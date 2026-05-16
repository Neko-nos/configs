"""
Encode and decode zsh history files.

Source references:
    zsh revision: 1328291abbb80e90dc4473a4396daffb0e919827
    Meta: https://github.com/zsh-users/zsh/blob/1328291abbb80e90dc4473a4396daffb0e919827/Src/zsh.h#L138-L144
    Marker: https://github.com/zsh-users/zsh/blob/1328291abbb80e90dc4473a4396daffb0e919827/Src/zsh.h#L224
    IMETA: https://github.com/zsh-users/zsh/blob/1328291abbb80e90dc4473a4396daffb0e919827/Src/init.c#L1871-L1875
    metafy: https://github.com/zsh-users/zsh/blob/1328291abbb80e90dc4473a4396daffb0e919827/Src/utils.c#L4862-L4911
    unmetafy: https://github.com/zsh-users/zsh/blob/1328291abbb80e90dc4473a4396daffb0e919827/Src/utils.c#L4958-L4961
"""

from __future__ import annotations

import fcntl
import os
import re
from collections.abc import Iterator
from contextlib import contextmanager
from pathlib import Path
from typing import BinaryIO

META = 0x83
MARKER = 0xA2
XOR_MASK = 0x20
# : <beginning time>:<elapsed seconds>;<command>
# See more details in `man zshoptions` under `EXTENDED_HISTORY`
RAW_HEADER_RE = re.compile(rb"^: \d+:\d+;")


def _needs_metafy(byte: int) -> bool:
    """Return whether zsh would escape a byte.

    Args:
        byte (int): Byte value to test.

    Returns:
        bool: True if the byte belongs to zsh's IMETA set.
    """

    return byte == 0 or META <= byte <= MARKER


def unmetafy(data: bytes) -> bytes:
    """Decode zsh metafied bytes.

    Args:
        data (bytes): Bytes read from a zsh history file.

    Returns:
        bytes: Original bytes before zsh metafication.

    Raises:
        ValueError: A zsh meta marker appears without a following byte.
    """

    decoded = bytearray()
    index = 0
    while index < len(data):
        byte = data[index]
        if byte == META:
            index += 1
            if index >= len(data):
                msg = "zsh meta marker is missing its escaped byte"
                raise ValueError(msg)
            decoded.append(data[index] ^ XOR_MASK)
        else:
            decoded.append(byte)
        index += 1
    return bytes(decoded)


def metafy(data: bytes) -> bytes:
    """Encode bytes using zsh metafication.

    Args:
        data (bytes): Raw bytes to encode for zsh history storage.

    Returns:
        bytes: Metafied bytes compatible with zsh history files.
    """

    encoded = bytearray()
    for byte in data:
        if _needs_metafy(byte):
            encoded.append(META)
            encoded.append(byte ^ XOR_MASK)
        else:
            encoded.append(byte)
    return bytes(encoded)


def _decode_history_entry_bytes(data: bytes) -> str:
    """Decode one zsh history entry from bytes into text.

    Args:
        data (bytes): Raw bytes for one zsh history entry.

    Returns:
        str: Decoded history entry text.

    Raises:
        UnicodeDecodeError: The unmetafied bytes are not valid UTF-8.
        ValueError: The metafied byte stream is malformed.
    """

    return unmetafy(data).decode("utf-8", errors="strict")


def _split_history_entry_bytes(data: bytes) -> list[bytes]:
    """Split raw zsh history bytes into entry-sized chunks.

    Args:
        data (bytes): Bytes read from a zsh history file.

    Returns:
        list[bytes]: Raw history entry byte chunks.
    """

    entries: list[bytes] = []
    current_lines: list[bytes] | None = None

    for line in data.splitlines(keepends=True):
        if RAW_HEADER_RE.match(line) is not None:
            if current_lines is not None:
                entries.append(b"".join(current_lines))
            current_lines = [line]
        elif current_lines is not None:
            current_lines.append(line)
        else:
            entries.append(line)

    if current_lines is not None:
        entries.append(b"".join(current_lines))

    return entries


def decode_history_bytes(data: bytes) -> tuple[str, bool]:
    """Decode zsh history bytes and report whether malformed entries were dropped.

    Args:
        data (bytes): Bytes read from a zsh history file.

    Returns:
        tuple[str, bool]: Decoded history text and whether any entries were dropped.
    """

    decoded_entries: list[str] = []
    dropped_invalid = False
    for entry in _split_history_entry_bytes(data):
        try:
            decoded_entries.append(_decode_history_entry_bytes(entry))
        except (UnicodeDecodeError, ValueError):
            dropped_invalid = True

    return "".join(decoded_entries), dropped_invalid


def encode_history_text(text: str) -> bytes:
    """Encode text for writing to a zsh history file.

    Args:
        text (str): History text to write.

    Returns:
        bytes: Encoded bytes for zsh history storage.
    """

    return metafy(text.encode("utf-8"))


@contextmanager
def locked_history_file(histfile: Path) -> Iterator[BinaryIO]:
    """Hold an exclusive fcntl lock on a zsh history file.

    Args:
        histfile (Path): History file path.
    """

    histfile.parent.mkdir(parents=True, exist_ok=True)
    with histfile.open("a+b") as history_file:
        # Match zsh's HIST_FCNTL_LOCK so Python helpers cooperate with zsh.
        # ref: https://github.com/zsh-users/zsh/blob/zsh-5.9/Src/hist.c#L2866-L2878
        fcntl.lockf(history_file.fileno(), fcntl.LOCK_EX)
        yield history_file


def read_locked_history_bytes(history_file: BinaryIO) -> bytes:
    """Read all bytes from a locked history file handle.

    Args:
        history_file (BinaryIO): Locked history file handle.

    Returns:
        bytes: Current history file bytes.
    """

    history_file.seek(0)
    return history_file.read()


def write_locked_history_bytes(history_file: BinaryIO, data: bytes) -> None:
    """Replace a locked history file with raw encoded bytes.

    Args:
        history_file (BinaryIO): Locked history file handle.
        data (bytes): Encoded history bytes to write.
    """

    history_file.seek(0)
    history_file.truncate()
    history_file.write(data)
    history_file.flush()
    os.fsync(history_file.fileno())


def read_locked_history_text(history_file: BinaryIO) -> str:
    """Read decoded zsh history text from a locked file handle.

    Args:
        history_file (BinaryIO): Locked history file handle.

    Returns:
        str: Decoded history text without malformed entries.
    """

    text, dropped_invalid = decode_history_bytes(
        read_locked_history_bytes(history_file)
    )
    if dropped_invalid:
        write_locked_history_text(history_file, text)
    return text


def write_locked_history_text(history_file: BinaryIO, text: str) -> None:
    """Write decoded text to a locked zsh history file handle.

    Args:
        history_file (BinaryIO): Locked history file handle.
        text (str): Decoded history text to write.
    """

    write_locked_history_bytes(history_file, encode_history_text(text))
