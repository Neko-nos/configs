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

from pathlib import Path

META = 0x83
MARKER = 0xA2
XOR_MASK = 0x20


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


def decode_history_bytes(data: bytes) -> str:
    """Decode bytes from a zsh history file into text.

    Args:
        data (bytes): Bytes read from a zsh history file.

    Returns:
        str: Decoded history text.

    Raises:
        UnicodeDecodeError: The unmetafied bytes are not valid UTF-8.
        ValueError: The metafied byte stream is malformed.
    """

    return unmetafy(data).decode("utf-8", errors="strict")


def encode_history_text(text: str) -> bytes:
    """Encode text for writing to a zsh history file.

    Args:
        text (str): History text to write.

    Returns:
        bytes: Encoded bytes for zsh history storage.
    """

    return metafy(text.encode("utf-8"))


def read_history_text(histfile: Path) -> str:
    """Read a zsh history file as decoded text.

    Args:
        histfile (Path): History file path.

    Returns:
        str: Decoded history text.

    Raises:
        UnicodeDecodeError: The unmetafied bytes are not valid UTF-8.
        ValueError: The metafied byte stream is malformed.
    """

    return decode_history_bytes(histfile.read_bytes())


def write_history_text(histfile: Path, text: str) -> None:
    """Write decoded text to a zsh history file.

    Args:
        histfile (Path): History file path.
        text (str): Decoded history text to write.
    """

    histfile.write_bytes(encode_history_text(text))
