"""
Deduplicate a zsh history file by command, keeping the latest entry.
"""

from __future__ import annotations

import argparse
import os
from pathlib import Path

from history_utils import parse_entries


def dedup_history_file(histfile: Path) -> bool:
    """Deduplicate the history file by command, keeping the latest entry.

    Args:
        histfile (Path): History file path.

    Returns:
        bool: True if the file was changed, False otherwise.
    """

    text = histfile.read_text(encoding="utf-8", errors="replace")
    entries = parse_entries(text)

    last_index: dict[str, int] = {}
    dup_found = False
    for idx, entry in enumerate(entries):
        cmd = entry.command_text()
        if cmd in last_index:
            dup_found = True
        last_index[cmd] = idx

    if not dup_found:
        return False

    remaining = [
        entry
        for idx, entry in enumerate(entries)
        if last_index[entry.command_text()] == idx
    ]
    new_text = "".join("".join(entry.lines) for entry in remaining)
    histfile.write_text(new_text, encoding="utf-8")
    return True


def build_parser() -> argparse.ArgumentParser:
    """Build the CLI argument parser.

    Returns:
        argparse.ArgumentParser: Configured argument parser.
    """

    parser = argparse.ArgumentParser(
        description="Deduplicate a zsh history file by command, keeping the latest entry.",
    )
    parser.add_argument(
        "--histfile",
        default=None,
        help="Path to the zsh history file. Defaults to $HISTFILE when omitted.",
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
        return 0

    # We have to expand ~ in the path, otherwise it causes FileNotFoundError.
    histfile = Path(histfile_value).expanduser()
    if not histfile.exists() or not histfile.is_file():
        return 0

    dedup_history_file(histfile)
    return 0


if __name__ == "__main__":
    # Propagate the return code from main() as the process exit status.
    raise SystemExit(main())
