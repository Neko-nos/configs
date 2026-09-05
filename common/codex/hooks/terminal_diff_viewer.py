import argparse
import json
import os
import re
import select
import shutil
import sys
import termios
import tty
import unicodedata
from pathlib import Path

ANSI_ESCAPE_RE = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")


def character_width(character: str, column: int) -> int:
    """
    Return the terminal width of one character.

    Args:
        character (str): Character to measure.
        column (int): Current terminal column.

    Returns:
        int: Number of terminal columns occupied.
    """
    if character == "\t":
        return 4 - column % 4
    if unicodedata.combining(character):
        return 0
    if unicodedata.east_asian_width(character) in {"F", "W"}:
        return 2
    return 1


def text_width(text: str) -> int:
    """
    Return the displayed width of plain terminal text.

    Args:
        text (str): Text to measure.

    Returns:
        int: Display width in terminal columns.
    """
    width = 0
    for character in text:
        width += character_width(character, width)
    return width


def truncate_text(text: str, width: int) -> str:
    """
    Truncate plain text to a terminal width.

    Args:
        text (str): Text to truncate.
        width (int): Maximum terminal width.

    Returns:
        str: Truncated text.
    """
    if text_width(text) <= width:
        return text

    truncated = []
    column = 0
    for character in text:
        character_columns = character_width(character, column)
        if column + character_columns > width - 1:
            break
        truncated.append(character)
        column += character_columns
    return "".join(truncated) + "…"


def truncate_ansi(text: str, width: int) -> str:
    """
    Truncate ANSI-styled text without splitting escape sequences.

    Args:
        text (str): ANSI-styled text.
        width (int): Maximum terminal width.

    Returns:
        str: Truncated ANSI text with its style reset.
    """
    truncated = []
    column = 0
    index = 0
    while index < len(text):
        match = ANSI_ESCAPE_RE.match(text, index)
        if match is not None:
            truncated.append(match.group())
            index = match.end()
            continue

        character = text[index]
        character_columns = character_width(character, column)
        if column + character_columns > width:
            break
        truncated.append(character)
        column += character_columns
        index += 1
    return "".join(truncated) + "\x1b[0m"


def file_list_lines(
    entries: list[dict[str, object]], selected: int, width: int, height: int
) -> list[str]:
    """
    Render the interactive file selection view.

    Args:
        entries (list[dict[str, object]]): Diff manifest entries.
        selected (int): Selected file index.
        width (int): Terminal width.
        height (int): Terminal height.

    Returns:
        list[str]: ANSI-styled screen lines.
    """
    added = sum(int(entry["added"]) for entry in entries)
    removed = sum(int(entry["removed"]) for entry in entries)
    file_word = "file" if len(entries) == 1 else "files"
    lines = [
        "\x1b[1m╭─ Turn diff\x1b[0m",
        (
            f"│  \x1b[2m{len(entries)} {file_word} changed\x1b[0m "
            f"\x1b[32m+{added}\x1b[0m \x1b[31m-{removed}\x1b[0m"
        ),
        "│",
    ]

    visible_count = min(5, max(1, height - 7))
    start = max(0, selected - visible_count // 2)
    start = min(start, max(0, len(entries) - visible_count))
    end = min(len(entries), start + visible_count)
    if start > 0:
        lines.append(f"│  \x1b[2m↑ {start} more\x1b[0m")

    content_width = max(10, width - 4)
    for index in range(start, end):
        entry = entries[index]
        stats = f"+{entry['added']} -{entry['removed']}"
        path_width = max(1, content_width - text_width(stats) - 3)
        path = truncate_text(str(entry["title"]), path_width)
        padding = " " * max(1, path_width - text_width(path) + 1)
        pointer = "❯ " if index == selected else "  "
        row = (
            f"{pointer}{path}{padding}"
            f"\x1b[32m+{entry['added']}\x1b[39m "
            f"\x1b[31m-{entry['removed']}\x1b[39m"
        )
        if index == selected:
            row = f"\x1b[1;7m{row}\x1b[0m"
        lines.append(f"│ {row}")

    if end < len(entries):
        lines.append(f"│  \x1b[2m↓ {len(entries) - end} more\x1b[0m")
    lines.extend(
        [
            "│",
            "\x1b[2m╰─ ↑/↓ select · Enter view · Esc close\x1b[0m",
        ]
    )
    return lines


def detail_lines(
    entry: dict[str, object], scroll: int, width: int, height: int
) -> tuple[list[str], int]:
    """
    Render the selected file's scrollable detail view.

    Args:
        entry (dict[str, object]): Selected diff manifest entry.
        scroll (int): First visible diff line.
        width (int): Terminal width.
        height (int): Terminal height.

    Returns:
        tuple[list[str], int]: Screen lines and the largest valid scroll offset.
    """
    diff_lines = Path(str(entry["path"])).read_text(encoding="utf-8").splitlines()
    body_height = max(1, height - 2)
    maximum_scroll = max(0, len(diff_lines) - body_height)
    scroll = min(scroll, maximum_scroll)
    visible = diff_lines[scroll : scroll + body_height]
    title = truncate_text(str(entry["title"]), max(1, width - 15))
    lines = [f"\x1b[1m╭─ Turn diff · {title}\x1b[0m"]
    lines.extend(visible)
    lines.append("\x1b[2m╰─ ↑/↓ scroll · Space page down · B page up · Esc back\x1b[0m")
    return lines, maximum_scroll


def draw_screen(lines: list[str], width: int, height: int) -> None:
    """
    Redraw a fullscreen terminal view.

    Args:
        lines (list[str]): ANSI-styled lines to display.
        width (int): Terminal width.
        height (int): Terminal height.
    """
    output = ["\x1b[H"]
    for row in range(height):
        output.append("\x1b[2K")
        if row < len(lines):
            output.append(truncate_ansi(lines[row], width))
        if row < height - 1:
            output.append("\r\n")
    sys.stdout.write("".join(output))
    sys.stdout.flush()


def read_key(file_descriptor: int) -> bytes | None:
    """
    Read one terminal key sequence.

    Args:
        file_descriptor (int): Terminal input file descriptor.

    Returns:
        bytes | None: Key sequence, or None while waiting for input.
    """
    if not select.select([file_descriptor], [], [], 0.2)[0]:
        return None

    key = os.read(file_descriptor, 1)
    if key != b"\x1b":  # Escape
        return key
    while select.select([file_descriptor], [], [], 0.02)[0]:
        key += os.read(file_descriptor, 16)
    return key


def view_turn(manifest_path: Path) -> None:
    """
    Open an interactive turn diff viewer.

    Args:
        manifest_path (Path): JSON manifest containing diff titles and paths.
    """
    entries = json.loads(manifest_path.read_text(encoding="utf-8"))
    file_descriptor = sys.stdin.fileno()
    original_terminal_attributes = termios.tcgetattr(file_descriptor)
    selected = 0
    is_showing_detail = False
    scroll = 0
    screen_size = (0, 0)
    maximum_scroll = 0
    should_redraw = True

    try:
        tty.setraw(file_descriptor)
        sys.stdout.write("\x1b[?1049h\x1b[?25l")
        sys.stdout.flush()
        while True:
            width, height = shutil.get_terminal_size()
            if should_redraw or screen_size != (width, height):
                if is_showing_detail:
                    lines, maximum_scroll = detail_lines(
                        entries[selected], scroll, width, height
                    )
                    scroll = min(scroll, maximum_scroll)
                else:
                    lines = file_list_lines(entries, selected, width, height)
                draw_screen(lines, width, height)
                screen_size = (width, height)
                should_redraw = False

            key = read_key(file_descriptor)
            if key is None:
                continue
            should_redraw = True
            if key == b"\x03":  # Ctrl+C
                break

            if is_showing_detail:
                body_height = max(1, height - 2)
                if key == b"\x1b":  # Escape
                    is_showing_detail = False
                    scroll = 0
                elif key == b"\x1b[A":  # Up Arrow
                    scroll = max(0, scroll - 1)
                elif key == b"\x1b[B":  # Down Arrow
                    scroll = min(maximum_scroll, scroll + 1)
                elif key == b"b":  # B
                    scroll = max(0, scroll - body_height)
                elif key == b" ":  # Space
                    scroll = min(maximum_scroll, scroll + body_height)
                continue

            if key == b"\x1b":  # Escape
                break
            if key == b"\x1b[A":  # Up Arrow
                selected = max(0, selected - 1)
            elif key == b"\x1b[B":  # Down Arrow
                selected = min(len(entries) - 1, selected + 1)
            elif key in {b"\r", b"\n"}:  # Enter
                is_showing_detail = True
                scroll = 0
    finally:
        termios.tcsetattr(
            file_descriptor, termios.TCSADRAIN, original_terminal_attributes
        )
        sys.stdout.write("\x1b[0m\x1b[?25h\x1b[?1049l")
        sys.stdout.flush()


def main() -> int:
    """
    Open a rendered turn diff.

    Returns:
        int: Process exit status.
    """
    parser = argparse.ArgumentParser(description="View a Codex turn diff.")
    parser.add_argument("-m", "--manifest", type=Path, required=True)
    args = parser.parse_args()
    view_turn(args.manifest)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
