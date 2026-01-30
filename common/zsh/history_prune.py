"""
Remove the last matching command entry from a zsh history file.

This script supports extended history format and preserves multiline commands.
"""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

from history_utils import parse_entries


def read_command(args: argparse.Namespace) -> str:
    """Read the command string from args or stdin.

    Args:
        args (argparse.Namespace): Parsed CLI arguments.

    Returns:
        str: Command text to match.
    """
    if args.command is None or args.command == "-":
        command = sys.stdin.read()
    else:
        command = args.command
    if command.endswith("\n"):
        return command[:-1]
    return command


def prune_history_file(histfile: Path, command: str) -> bool:
    """Remove the last matching command entry from the history file.

    Args:
        histfile (Path): History file path.
        command (str): Command text to remove.

    Returns:
        bool: True if a matching entry was removed, False otherwise.
    """
    text = histfile.read_text(encoding="utf-8", errors="replace")
    entries = parse_entries(text)

    last_index = -1
    for idx, entry in enumerate(entries):
        if entry.command_text() == command:
            last_index = idx

    if last_index == -1:
        return False

    remaining = entries[:last_index] + entries[last_index + 1 :]
    new_text = "".join("".join(entry.lines) for entry in remaining)
    histfile.write_text(new_text, encoding="utf-8")
    return True


def build_parser() -> argparse.ArgumentParser:
    """Build the CLI argument parser.

    Returns:
        argparse.ArgumentParser: Configured argument parser.
    """
    parser = argparse.ArgumentParser(
        description="Remove the last matching command entry from a zsh history file.",
    )
    parser.add_argument(
        "--histfile",
        default=None,
        help="Path to the zsh history file. Defaults to $HISTFILE when omitted.",
    )
    parser.add_argument(
        "--command",
        default=None,
        help="Command string to remove. Use '-' or omit to read from stdin.",
    )
    parser.add_argument(
        "--status",
        type=int,
        default=1,
        help="Exit status of the command. If 0, no changes are made.",
    )
    return parser


def main() -> int:
    """Run the CLI.

    Returns:
        int: Exit status code.
    """
    parser = build_parser()
    args = parser.parse_args()

    if args.status == 0:
        return 0

    histfile_value = args.histfile or os.environ.get("HISTFILE")
    if not histfile_value:
        return 0

    # We have to expand ~ in the path, otherwise it causes FileNotFoundError.
    histfile = Path(histfile_value).expanduser()
    if not histfile.exists() or not histfile.is_file():
        return 0

    command = read_command(args)
    if not command:
        return 0

    prune_history_file(histfile, command)
    return 0


if __name__ == "__main__":
    # Propagate the return code from main() as the process exit status.
    raise SystemExit(main())
