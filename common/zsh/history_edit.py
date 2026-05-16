"""
Edit a zsh history file through a normal text editor.
"""

from __future__ import annotations

import argparse
import fcntl
import os
import shlex
import subprocess
import sys
import tempfile
from collections.abc import Iterator
from contextlib import contextmanager
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import BinaryIO, TextIO

from history_codec import decode_history_bytes, encode_history_text
from history_utils import parse_entries

ABORT_FILE_PREFIX = "zsh-history-edit-abort"


class HistoryEditError(RuntimeError):
    """Raised when history editing cannot be completed safely."""


@dataclass(frozen=True)
class ExternalAppend:
    """Decoded history entries appended by another shell.

    Attributes:
        text (str): Decoded appended history text.
        entry_count (int): Number of decoded appended entries.
    """

    text: str
    entry_count: int


@dataclass(frozen=True)
class EditResult:
    """Result of a history edit session.

    Attributes:
        editor_append_count (int): Entries appended while the editor was open.
        save_append_count (int): Entries appended during the final save step.
    """

    editor_append_count: int
    save_append_count: int


def _lock_path(histfile: Path) -> Path:
    """Return the per-history-file editor lock path.

    Args:
        histfile (Path): History file path.

    Returns:
        Path: Lock file path.
    """

    return histfile.with_name(f"{histfile.name}.edit.lock")


@contextmanager
def _exclusive_editor_lock(lockfile: Path) -> Iterator[None]:
    """Hold a non-blocking lock that prevents concurrent history editors.

    Args:
        lockfile (Path): Lock file path.

    Raises:
        HistoryEditError: Another history editor already holds the lock.
    """

    lockfile.parent.mkdir(parents=True, exist_ok=True)
    with lockfile.open("a", encoding="utf-8") as lock:
        try:
            fcntl.lockf(lock.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as exc:
            msg = f"another zsh history editor is already running: {lockfile}"
            raise HistoryEditError(msg) from exc
        yield


@contextmanager
def _history_file_lock(histfile: Path) -> Iterator[BinaryIO]:
    """Hold a short fcntl lock while reading and writing the history file.

    Args:
        histfile (Path): History file path.
    """

    histfile.parent.mkdir(parents=True, exist_ok=True)
    with histfile.open("a+b") as history_file:
        # Match zsh's HIST_FCNTL_LOCK: an exclusive fcntl lock over the entire history file.
        # ref: https://github.com/zsh-users/zsh/blob/zsh-5.9/Src/hist.c#L2866-L2878
        fcntl.lockf(history_file.fileno(), fcntl.LOCK_EX)
        yield history_file


def _read_locked_bytes(history_file: BinaryIO) -> bytes:
    """Read all bytes from a locked history file handle.

    Args:
        history_file (BinaryIO): Locked file handle.

    Returns:
        bytes: Current history file bytes.
    """

    history_file.seek(0)
    return history_file.read()


def _write_locked_bytes(
    history_file: BinaryIO,
    data: bytes,
) -> None:
    """Replace a locked history file with encoded bytes.

    Args:
        history_file (BinaryIO): Locked file handle.
        data (bytes): Encoded history bytes to write.
    """

    history_file.seek(0)
    history_file.truncate()
    history_file.write(data)
    history_file.flush()
    os.fsync(history_file.fileno())


def _timestamped_home_path(reason: str, suffix: str) -> Path:
    """Build a timestamped abort artifact path under the home directory.

    Args:
        reason (str): Short reason slug.
        suffix (str): File suffix.

    Returns:
        Path: Timestamped home-directory path.
    """

    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    return Path.home() / f"{ABORT_FILE_PREFIX}-{reason}-{timestamp}{suffix}"


def _save_edited_history(text: str) -> Path:
    """Save editor contents when an edit session aborts after editing.

    Args:
        text (str): Edited decoded history text.

    Returns:
        Path: Path where editor contents were saved.
    """

    output_path = _timestamped_home_path("edited", ".txt")
    output_path.write_text(text, encoding="utf-8", newline="")
    return output_path


def _decode_external_append(base_bytes: bytes, current_bytes: bytes) -> ExternalAppend:
    """Decode bytes appended after a known history snapshot.

    Args:
        base_bytes (bytes): Previously observed history bytes.
        current_bytes (bytes): Current history bytes.

    Returns:
        ExternalAppend: Decoded appended entries.

    Raises:
        HistoryEditError: The file changed in a non-append-only way.
    """

    if current_bytes == base_bytes:
        return ExternalAppend(text="", entry_count=0)
    if not current_bytes.startswith(base_bytes):
        msg = (
            "history file changed in a non-append-only way; "
            "aborting to avoid losing history"
        )
        raise HistoryEditError(msg)

    appended_text, dropped_invalid = decode_history_bytes(
        current_bytes[len(base_bytes) :]
    )
    if dropped_invalid:
        msg = "appended history contains malformed entries; aborting"
        raise HistoryEditError(msg)
    return ExternalAppend(
        text=appended_text,
        entry_count=len(parse_entries(appended_text)),
    )


def _select_editor_command(
    editor: str | None,
    environ: dict[str, str],
) -> list[str]:
    """Select an editor command.

    Args:
        editor (str | None): Explicit editor command.
        environ (dict[str, str]): Environment variables.

    Returns:
        list[str]: Command and arguments.

    Raises:
        HistoryEditError: No supported editor is available.
    """

    editor_value = editor or environ.get("VISUAL") or environ.get("EDITOR")
    if editor_value:
        return shlex.split(editor_value)

    msg = "no editor found; pass --editor or set VISUAL or EDITOR"
    raise HistoryEditError(msg)


def _run_editor(editor_command: list[str], edit_path: Path) -> None:
    """Run the selected editor.

    Args:
        editor_command (list[str]): Editor command and arguments.
        edit_path (Path): Decoded history file to edit.

    Raises:
        HistoryEditError: The editor exits with a non-zero status.
    """

    try:
        subprocess.run([*editor_command, str(edit_path)], check=True)
    except FileNotFoundError as exc:
        msg = f"editor command not found: {editor_command[0]}"
        raise HistoryEditError(msg) from exc
    except subprocess.CalledProcessError as exc:
        msg = f"editor exited with status {exc.returncode}: {editor_command[0]}"
        raise HistoryEditError(msg) from exc


def _write_merged_history(
    histfile: Path,
    edited_text: str,
    known_bytes: bytes,
) -> tuple[int, bytes]:
    """Write edited history while preserving newly appended entries.

    Args:
        histfile (Path): History file path.
        edited_text (str): Edited decoded history text.
        known_bytes (bytes): Latest observed encoded history bytes.

    Returns:
        tuple[int, bytes]: Number of appended entries merged and bytes written.
    """

    with _history_file_lock(histfile) as history_file:
        current_bytes = _read_locked_bytes(history_file)
        append = _decode_external_append(known_bytes, current_bytes)
        merged_text = edited_text + append.text
        encoded = encode_history_text(merged_text)
        _write_locked_bytes(history_file, encoded)
        return append.entry_count, encoded


def edit_history_file(
    histfile: Path,
    editor_command: list[str],
    stdout: TextIO = sys.stdout,
) -> EditResult:
    """Edit a zsh history file and merge append-only external changes.

    Args:
        histfile (Path): History file path.
        editor_command (list[str]): Editor command and arguments.
        stdout (TextIO): Stream for user-facing status messages.

    Returns:
        EditResult: Counts of externally appended entries.
    """

    histfile = histfile.expanduser()
    lockfile = _lock_path(histfile)

    with (
        _exclusive_editor_lock(lockfile),
        tempfile.TemporaryDirectory(
            prefix="zsh-history-edit.",
        ) as tmpdir,
    ):
        with _history_file_lock(histfile) as history_file:
            base_bytes = _read_locked_bytes(history_file)

        decoded_text, dropped_invalid = decode_history_bytes(base_bytes)
        if dropped_invalid:
            msg = "history contains malformed entries; aborting"
            raise HistoryEditError(msg)

        edit_path = Path(tmpdir) / "history.txt"
        edit_path.write_text(decoded_text, encoding="utf-8", newline="")

        _run_editor(editor_command, edit_path)

        edited_text = edit_path.read_text(encoding="utf-8")
        try:
            with _history_file_lock(histfile) as history_file:
                current_bytes = _read_locked_bytes(history_file)
            editor_append = _decode_external_append(base_bytes, current_bytes)
            if editor_append.entry_count > 0:
                edited_text += editor_append.text
                print(
                    "Appended "
                    f"{editor_append.entry_count} external history "
                    "entry/entries added while the editor was open.",
                    file=stdout,
                )

            save_append_count, _ = _write_merged_history(
                histfile=histfile,
                edited_text=edited_text,
                known_bytes=current_bytes,
            )
        except HistoryEditError as exc:
            saved_path = _save_edited_history(edited_text)
            msg = f"{exc}. edited history was saved to {saved_path}"
            raise HistoryEditError(msg) from exc
        if save_append_count > 0:
            print(
                "Appended "
                f"{save_append_count} external history entry/entries "
                "added during save.",
                file=stdout,
            )

        return EditResult(
            editor_append_count=editor_append.entry_count,
            save_append_count=save_append_count,
        )


def build_parser() -> argparse.ArgumentParser:
    """Build the CLI argument parser.

    Returns:
        argparse.ArgumentParser: Configured argument parser.
    """

    parser = argparse.ArgumentParser(
        description="Edit a zsh history file with a normal text editor.",
    )
    parser.add_argument(
        "--histfile",
        default=None,
        help="Path to the zsh history file. Defaults to $HISTFILE when omitted.",
    )
    parser.add_argument(
        "--editor",
        default=None,
        help="Editor command. Defaults to $VISUAL, then $EDITOR.",
    )
    return parser


def main() -> int:
    """Run the CLI.

    Returns:
        int: Exit status code.
    """

    parser = build_parser()
    args = parser.parse_args()

    histfile_value = args.histfile or os.environ.get("HISTFILE")
    if not histfile_value:
        print("HISTFILE is not set; pass --histfile explicitly.", file=sys.stderr)
        return 1

    try:
        editor_command = _select_editor_command(args.editor, os.environ)
        edit_history_file(Path(histfile_value), editor_command)
    except HistoryEditError as exc:
        print(f"zsh-history-edit: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
