"""
Shared utilities for zsh history processing scripts.
"""

from __future__ import annotations

import re
from dataclasses import dataclass

# : <beginning time>:<elapsed seconds>;<command>
# See more details in `man zshoptions` under `EXTENDED_HISTORY`
HEADER_RE = re.compile(r"^: \d+:\d+;")


@dataclass(frozen=True)
class HistoryEntry:
    """A parsed history entry with original lines preserved.

    Attributes:
        lines (list[str]): Raw lines for the entry, including newlines.
        has_header (bool): Whether the entry starts with an extended history header.
    """

    lines: list[str]
    has_header: bool

    def command_text(self) -> str:
        """Extract the command text for comparison.

        Returns:
            str: Command text with extended history header removed.
        """

        if self.has_header:
            first = HEADER_RE.sub("", self.lines[0], count=1)
            rest = "".join(self.lines[1:])
            cmd = first + rest
        else:
            cmd = "".join(self.lines)
        if cmd.endswith("\n"):
            return cmd[:-1]
        return cmd


def parse_entries(text: str) -> list[HistoryEntry]:
    """Parse history file contents into entries.

    Args:
        text (str): Full history file contents.

    Returns:
        list[HistoryEntry]: Parsed entries in original order.
    """

    entries: list[HistoryEntry] = []
    current_lines: list[str] | None = None

    # Keep newlines to ensure exact reconstruction when writing back to file.
    for line in text.splitlines(keepends=True):
        if HEADER_RE.match(line) is not None:
            # In extended history, only the first line of a command has a header.
            # Any following lines belong to the same command until the next header.
            if current_lines is not None:
                entries.append(HistoryEntry(lines=current_lines, has_header=True))
            current_lines = [line]
        else:
            # The rest of the lines belong to the same command until the next header.
            if current_lines is not None:
                current_lines.append(line)
            else:
                # We support non-extended history entries as well.
                entries.append(HistoryEntry(lines=[line], has_header=False))

    if current_lines is not None:
        entries.append(HistoryEntry(lines=current_lines, has_header=True))

    return entries
