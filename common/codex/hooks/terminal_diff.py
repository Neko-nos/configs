import json
import os
import subprocess
from pathlib import Path


def parse_hunk_header(line: str) -> tuple[int, int]:
    """
    Parse old and new starting line numbers from a unified diff hunk.

    Args:
        line (str): Hunk header line.

    Returns:
        tuple[int, int]: Old and new line numbers.
    """
    parts = line.split()
    old_start = int(parts[1].split(",", maxsplit=1)[0].removeprefix("-"))
    new_start = int(parts[2].split(",", maxsplit=1)[0].removeprefix("+"))
    return old_start, new_start


def ansi_code(
    foreground: int | None = None,
    background: tuple[int, int, int] | None = None,
    dim: bool = False,
    bold: bool = False,
) -> str:
    """
    Build an ANSI SGR sequence.

    Args:
        foreground (int | None): Optional SGR foreground.
        background (tuple[int, int, int] | None): Optional RGB background.
        dim (bool): Whether to enable dim text.
        bold (bool): Whether to enable bold text.

    Returns:
        str: ANSI SGR sequence.
    """
    parts = []
    if bold:
        parts.append("1")
    if dim:
        parts.append("2")
    if foreground is not None:
        parts.append(str(foreground))
    if background is not None:
        parts.append(f"48;2;{background[0]};{background[1]};{background[2]}")
    if not parts:
        return ""
    return f"\x1b[{';'.join(parts)}m"


def path_extension(path: str | None) -> str | None:
    """
    Return a file extension for syntax detection.

    Args:
        path (str | None): Repository-relative path.

    Returns:
        str | None: File extension, or None when the file type is unknown.
    """
    if path is None:
        return None
    return Path(path).suffix.removeprefix(".") or None


def highlighted_diff_sections(sections: list[list[str]]) -> list[list[str]]:
    """
    Highlight every diff hunk in one invocation of the installed helper.

    Args:
        sections (list[list[str]]): Per-file unified diff sections.

    Returns:
        list[list[str]]: Per-file content lines, highlighted when available.
    """
    section_hunks = [diff_section_hunks(section) for section in sections]
    requests = [
        (
            path_extension(section_path(section)),
            ["\n".join(lines) + "\n" for lines in hunks],
        )
        for section, hunks in zip(sections, section_hunks, strict=True)
    ]
    runtime_dir = (
        Path(
            os.environ.get("CODEX_SQLITE_HOME")
            or os.environ.get("CODEX_HOME", Path.home() / ".codex")
        )
        / "turn-diff"
    )
    try:
        result = subprocess.run(
            [str(runtime_dir / "bin/codex-syntect-highlight")],
            input=json.dumps(requests),
            text=True,
            capture_output=True,
            check=True,
            # Leave time to save the review within the hook's 30-second limit.
            timeout=5,
        )
    except (OSError, subprocess.CalledProcessError, subprocess.TimeoutExpired):
        highlighted_sections = [[None] * len(hunks) for hunks in section_hunks]
    else:
        highlighted_sections = json.loads(result.stdout)

    highlighted_files = []
    for hunks, highlighted_hunks in zip(
        section_hunks, highlighted_sections, strict=True
    ):
        highlighted_lines = []
        for lines, highlighted in zip(hunks, highlighted_hunks, strict=True):
            highlighted_lines.extend(
                lines if highlighted is None else highlighted.split("\n")[: len(lines)]
            )
        highlighted_files.append(highlighted_lines)
    return highlighted_files


def diff_section_hunks(section: list[str]) -> list[list[str]]:
    """
    Group diff content by hunk so each hunk starts with fresh syntax state.

    Args:
        section (list[str]): Per-file unified diff lines.

    Returns:
        list[list[str]]: Content lines grouped by hunk.
    """
    hunks = []
    hunk_lines: list[str] = []
    for line in section:
        if line.startswith("@@"):
            if hunk_lines:
                hunks.append(hunk_lines)
                hunk_lines = []
        elif (content := diff_content_text(line)) is not None:
            hunk_lines.append(content)
    if hunk_lines:
        hunks.append(hunk_lines)
    return hunks


def diff_content_text(line: str) -> str | None:
    """
    Return code text from a unified diff content line.

    Args:
        line (str): Unified diff line.

    Returns:
        str | None: Code text without the diff prefix, or None for metadata.
    """
    if line.startswith(("+", "-", " ")) and not line.startswith(("+++", "---")):
        return line[1:]
    return None


def strip_diff_path(path: str) -> str | None:
    """
    Return a repository path from a unified diff path field.

    Args:
        path (str): Unified diff path, such as `a/file.py` or `/dev/null`.

    Returns:
        str | None: Repository-relative path, or None for `/dev/null`.
    """
    # delete
    if path == "/dev/null":
        return None
    # normal edits
    if path.startswith(("a/", "b/")):
        return path[2:]
    raise RuntimeError(f"unexpected unified diff path: {path}")


def split_diff_sections(diff_text: str) -> list[list[str]]:
    """
    Split a unified diff into per-file sections.

    Args:
        diff_text (str): Unified diff text.

    Returns:
        list[list[str]]: Per-file diff sections.
    """
    sections = []
    current: list[str] = []
    for line in diff_text.splitlines():
        if line.startswith("diff --git ") and current:
            sections.append(current)
            current = []
        current.append(line)
    if current:
        sections.append(current)
    return sections


def section_path(section: list[str]) -> str | None:
    """
    Return the display path for a unified diff section.

    Args:
        section (list[str]): Per-file unified diff lines.

    Returns:
        str | None: Repository-relative path when available.
    """
    old_path = None
    for line in section:
        if line.startswith("--- "):
            old_path = strip_diff_path(line[4:])
        elif line.startswith("+++ "):
            return strip_diff_path(line[4:]) or old_path
    return None


def section_line_counts(section: list[str]) -> tuple[int, int]:
    """
    Count added and removed lines in one diff section.

    Args:
        section (list[str]): Per-file unified diff lines.

    Returns:
        tuple[int, int]: Added and removed line counts.
    """
    added = sum(
        1 for line in section if line.startswith("+") and not line.startswith("+++")
    )
    removed = sum(
        1 for line in section if line.startswith("-") and not line.startswith("---")
    )
    return added, removed


def render_terminal_diff_row(
    line_number: int,
    sign: str,
    text: str,
    line_number_width: int,
) -> str:
    """
    Render one Codex-like terminal diff row.

    Args:
        line_number (int): Line number to display.
        sign (str): Diff sign column.
        text (str): Code text, highlighted when available.
        line_number_width (int): Width of the line-number gutter.

    Returns:
        str: ANSI-rendered row.
    """
    if sign == "+":
        # ref: https://github.com/openai/codex/blob/da4c8ca57d40b074bdc1b5b1218851100150c56b/codex-rs/tui/src/diff_render.rs#L61
        background = (33, 58, 43)
        sign_color = 32
    elif sign == "-":
        # ref: https://github.com/openai/codex/blob/da4c8ca57d40b074bdc1b5b1218851100150c56b/codex-rs/tui/src/diff_render.rs#L62
        background = (74, 34, 29)
        sign_color = 31
    else:
        background = None
        sign_color = None

    # ref: https://github.com/nornagon/crossterm/blob/87db8bfa6dc99427fd3b071681b07fc31c6ce995/src/style/types/attribute.rs#L94
    reset = "\x1b[0m"
    gutter_text = f"{line_number:>{line_number_width}} "
    gutter = ansi_code(background=background, dim=True) + gutter_text
    sign_span = ansi_code(sign_color, background, bold=sign != " ") + sign
    content_style = ansi_code(background=background, dim=sign == "-")
    clear_to_end = f"{ansi_code(background=background)}\x1b[K" if background else ""
    return f"{gutter}{sign_span}{content_style}{text}{clear_to_end}{reset}"


def render_terminal_diff_section(
    section: list[str], highlighted_lines: list[str]
) -> tuple[str | None, str, int, int]:
    """
    Render one file section of a unified diff as Codex-like ANSI rows.

    Args:
        section (list[str]): Per-file unified diff lines.
        highlighted_lines (list[str]): Content lines, highlighted when available.

    Returns:
        tuple[str | None, str, int, int]: Display path, ANSI-rendered diff,
            and added and removed line counts.
    """
    # ref: https://github.com/nornagon/crossterm/blob/87db8bfa6dc99427fd3b071681b07fc31c6ce995/src/style/types/attribute.rs#L94
    reset = "\x1b[0m"
    path = section_path(section)
    added, deleted = section_line_counts(section)
    verb = "Edited"
    if added > 0 and deleted == 0:
        verb = "Added"
    elif deleted > 0 and added == 0:
        verb = "Deleted"

    header = (
        f"{ansi_code(dim=True)}• {reset}"
        f"{ansi_code(bold=True)}{verb}{reset} "
        f"{path or '<unknown>'} "
        # green for added, red for deleted
        f"({ansi_code(32)}+{added}{reset} {ansi_code(31)}-{deleted}{reset})"
    )
    lines = [header, ""]
    old_number = new_number = 0
    line_number_width = 1
    highlighted = iter(highlighted_lines)

    for line in section:
        if line.startswith("@@"):
            old_number, new_number = parse_hunk_header(line)
            line_number_width = max(
                len(str(old_number)),
                len(str(new_number)),
                line_number_width,
            )
            lines.append(f"{ansi_code(dim=True)}{line}{reset}")
        elif diff_content_text(line) is not None:
            sign = line[0]
            lines.append(
                render_terminal_diff_row(
                    old_number if sign == "-" else new_number,
                    sign,
                    next(highlighted),
                    line_number_width,
                ),
            )
            if sign != "+":
                old_number += 1
            if sign != "-":
                new_number += 1
        elif line.startswith(("Binary files ", "new file ", "deleted file ")):
            lines.append(f"{ansi_code(dim=True)}{line}{reset}")
    return path, "\n".join(lines) + "\n", added, deleted


def render_terminal_diff_files(
    diff_text: str,
) -> list[tuple[str | None, str, int, int]]:
    """
    Render a unified diff into per-file terminal output.

    Args:
        diff_text (str): Unified diff text.

    Returns:
        list[tuple[str | None, str, int, int]]: Display paths, ANSI-rendered
        diffs, and added and removed line counts.
    """
    sections = split_diff_sections(diff_text)
    highlighted_sections = highlighted_diff_sections(sections)
    return [
        render_terminal_diff_section(section, highlighted)
        for section, highlighted in zip(sections, highlighted_sections, strict=True)
    ]
