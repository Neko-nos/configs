import re
import subprocess
from pathlib import Path

ANSI_SGR_RE = re.compile(r"\x1b\[([0-9;]*)m")


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
    suffix = Path(path).suffix
    if suffix == "":
        return None
    return suffix.removeprefix(".")


def syntect_highlight_content_lines(
    extension: str, lines: list[str]
) -> list[str] | None:
    """
    Syntax-highlight content lines through a syntect-based highlighter.

    Args:
        extension (str): File extension used for syntax detection.
        lines (list[str]): Code lines.

    Returns:
        list[str] | None: ANSI-highlighted lines, or None for unsupported extensions.
    """
    result = subprocess.run(
        [
            "cargo",
            "run",
            "--quiet",
            "--manifest-path",
            str(Path(__file__).parent / "syntect_highlight/Cargo.toml"),
            "--",
            extension,
        ],
        input="\n".join(lines) + "\n",
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode != 0:
        return None
    highlighted = [
        keep_row_background(line) for line in result.stdout.split("\n")[: len(lines)]
    ]
    if len(highlighted) != len(lines):
        raise RuntimeError("syntect highlighter returned an unexpected line count")
    return highlighted


def highlighted_diff_section_lines(
    path: str | None,
    section: list[str],
) -> list[str | None]:
    """
    Syntax-highlight diff content lines by hunk.

    Args:
        path (str | None): Repository-relative path used for syntax detection.
        section (list[str]): Per-file unified diff lines.

    Returns:
        list[str | None]: Highlighted content lines, aligned to diff content lines.
    """
    highlighted_lines: list[str | None] = []
    hunk_lines: list[str] = []
    extension = path_extension(path)

    def flush_hunk() -> None:
        if not hunk_lines:
            return
        if extension is None:
            highlighted_lines.extend([None] * len(hunk_lines))
        else:
            highlighted_hunk = syntect_highlight_content_lines(extension, hunk_lines)
            if highlighted_hunk is None:
                highlighted_lines.extend([None] * len(hunk_lines))
            else:
                highlighted_lines.extend(highlighted_hunk)
        hunk_lines.clear()

    for line in section:
        if line.startswith("@@"):
            flush_hunk()
        elif (content := diff_content_text(line)) is not None:
            hunk_lines.append(content)
    flush_hunk()

    return highlighted_lines


def keep_row_background(text: str) -> str:
    """
    Remove ANSI background resets from embedded syntax-highlighted text.

    Args:
        text (str): ANSI-highlighted text.

    Returns:
        str: Text that can be rendered inside a diff row background.
    """

    def replace_sgr(match: re.Match[str]) -> str:
        raw_params = match.group(1)
        params = ["0"] if raw_params == "" else raw_params.split(";")
        if "0" in params or "00" in params:
            return "\x1b[39m"
        if "49" in params:
            params = [param for param in params if param != "49"]
        if not params:
            return ""
        return f"\x1b[{';'.join(params)}m"

    return ANSI_SGR_RE.sub(replace_sgr, text)


def diff_content_text(line: str) -> str | None:
    """
    Return code text from a unified diff content line.

    Args:
        line (str): Unified diff line.

    Returns:
        str | None: Code text without the diff prefix, or None for metadata.
    """
    if line.startswith("+") and not line.startswith("+++"):
        return line[1:]
    if line.startswith("-") and not line.startswith("---"):
        return line[1:]
    if line.startswith(" "):
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


def render_terminal_diff_row(
    line_number: int | None,
    sign: str,
    text: str,
    highlighted_text: str | None,
    line_number_width: int,
    background: tuple[int, int, int] | None,
    sign_color: int | None,
    dim_content: bool = False,
) -> str:
    """
    Render one Codex-like terminal diff row.

    Args:
        line_number (int | None): Line number to display.
        sign (str): Diff sign column.
        text (str): Code text.
        highlighted_text (str | None): Pre-highlighted code text.
        line_number_width (int): Width of the line-number gutter.
        background (tuple[int, int, int] | None): Optional line background.
        sign_color (int | None): Optional sign foreground.
        dim_content (bool): Whether syntax content should be dimmed.

    Returns:
        str: ANSI-rendered row.
    """
    # ref: https://github.com/nornagon/crossterm/blob/87db8bfa6dc99427fd3b071681b07fc31c6ce995/src/style/types/attribute.rs#L94
    reset = "\x1b[0m"
    number = "" if line_number is None else str(line_number)
    gutter_text = f"{number:>{line_number_width}} "
    gutter = ansi_code(background=background, dim=True) + gutter_text
    sign_span = ansi_code(sign_color, background, bold=sign != " ") + sign
    content_style = ansi_code(background=background, dim=dim_content)
    highlighted = highlighted_text if highlighted_text is not None else text
    clear_to_end = f"{ansi_code(background=background)}\x1b[K" if background else ""
    return f"{gutter}{sign_span}{content_style}{highlighted}{clear_to_end}{reset}"


def render_terminal_diff_section(section: list[str]) -> list[str]:
    """
    Render one file section of a unified diff as Codex-like ANSI rows.

    Args:
        section (list[str]): Per-file unified diff lines.

    Returns:
        list[str]: ANSI-rendered lines.
    """
    # ref: https://github.com/nornagon/crossterm/blob/87db8bfa6dc99427fd3b071681b07fc31c6ce995/src/style/types/attribute.rs#L94
    reset = "\x1b[0m"
    path = section_path(section)
    added = sum(
        1 for line in section if line.startswith("+") and not line.startswith("+++")
    )
    deleted = sum(
        1 for line in section if line.startswith("-") and not line.startswith("---")
    )
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
    old_number: int | None = None
    new_number: int | None = None
    line_number_width = 1
    highlighted_lines = highlighted_diff_section_lines(path, section)
    highlighted_index = 0

    for line in section:
        if line.startswith("@@"):
            old_number, new_number = parse_hunk_header(line)
            line_number_width = max(
                len(str(old_number)),
                len(str(new_number)),
                line_number_width,
            )
            lines.append(f"{ansi_code(dim=True)}{line}{reset}")
        elif line.startswith("+") and not line.startswith("+++"):
            highlighted = highlighted_lines[highlighted_index]
            highlighted_index += 1
            lines.append(
                render_terminal_diff_row(
                    new_number,
                    "+",
                    line[1:],
                    highlighted,
                    line_number_width,
                    # ref: https://github.com/openai/codex/blob/da4c8ca57d40b074bdc1b5b1218851100150c56b/codex-rs/tui/src/diff_render.rs#L61
                    (33, 58, 43),
                    32,
                ),
            )
            if new_number is not None:
                new_number += 1
        elif line.startswith("-") and not line.startswith("---"):
            highlighted = highlighted_lines[highlighted_index]
            highlighted_index += 1
            lines.append(
                render_terminal_diff_row(
                    old_number,
                    "-",
                    line[1:],
                    highlighted,
                    line_number_width,
                    # ref: https://github.com/openai/codex/blob/da4c8ca57d40b074bdc1b5b1218851100150c56b/codex-rs/tui/src/diff_render.rs#L62
                    (74, 34, 29),
                    31,
                    dim_content=True,
                ),
            )
            if old_number is not None:
                old_number += 1
        elif line.startswith(" ") and old_number is not None and new_number is not None:
            highlighted = highlighted_lines[highlighted_index]
            highlighted_index += 1
            lines.append(
                render_terminal_diff_row(
                    new_number,
                    " ",
                    line[1:],
                    highlighted,
                    line_number_width,
                    None,
                    None,
                ),
            )
            old_number += 1
            new_number += 1
        elif line.startswith(("diff --git ", "index ", "--- ", "+++ ")):
            continue
        elif line.startswith(("Binary files ", "new file ", "deleted file ")):
            lines.append(f"{ansi_code(dim=True)}{line}{reset}")
    return lines


def render_terminal_diff(diff_text: str) -> str:
    """
    Render a unified diff as Codex-like ANSI terminal output.

    Args:
        diff_text (str): Unified diff text.

    Returns:
        str: ANSI-rendered diff.
    """
    if diff_text == "":
        return ""
    rendered = []
    for section in split_diff_sections(diff_text):
        if rendered:
            rendered.append("")
        rendered.extend(render_terminal_diff_section(section))
    return "\n".join(rendered) + "\n"
