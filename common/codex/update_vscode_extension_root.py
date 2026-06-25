"""
Update the Codex config entry for the installed VS Code Codex extension.
"""

import argparse
import os
import re
import time
import warnings
from pathlib import Path

CONFIG_EXTENSION_ROOT_RE = re.compile(
    r'(?P<quote>["\'])~/\.vscode-server/extensions/'
    r"openai\.chatgpt-[^\"']+(?P=quote)"
)
EXTENSION_DIR_RE = re.compile(r"openai\.chatgpt-(?P<version>\d+(?:\.\d+)*)(?:-.+)?$")


def parse_version(path: Path) -> tuple[int, ...]:
    """Parse the VS Code extension version from an extension directory name.

    Args:
        path (Path): Extension directory path.

    Returns:
        tuple[int, ...]: Numeric version components. Empty when the name does
            not include a parseable version.
    """
    match = EXTENSION_DIR_RE.fullmatch(path.name)
    if not match:
        return ()
    return tuple(int(part) for part in match.group("version").split("."))


def find_latest_extension_dir(extension_root: Path) -> Path | None:
    """Find the newest installed Codex VS Code extension directory.

    Args:
        extension_root (Path): VS Code server extension directory.

    Returns:
        Path | None: Latest matching extension directory, or None if no
            matching directory exists.
    """
    if not extension_root.is_dir():
        return None

    candidates = [
        path
        for path in extension_root.iterdir()
        if path.is_dir() and EXTENSION_DIR_RE.fullmatch(path.name)
    ]
    if not candidates:
        return None

    return max(candidates, key=parse_version)


def current_config_extension_root(config_text: str) -> str | None:
    """Read the configured VS Code extension root from TOML text.

    Args:
        config_text (str): Codex config TOML text.

    Returns:
        str | None: Configured root without surrounding quotes, or None when
            no matching root exists.
    """
    match = CONFIG_EXTENSION_ROOT_RE.search(config_text)
    if not match:
        return None
    # The regex intentionally matches the whole TOML string so replacement can
    # preserve the original quote style; strip those surrounding quotes here.
    return match.group(0)[1:-1]


def extension_version(extension_dir_name: str) -> str:
    """Read the version text from a VS Code extension directory name.

    Args:
        extension_dir_name (str): Installed extension directory name.

    Returns:
        str: Parsed version, or the original directory name if parsing fails.
    """
    match = EXTENSION_DIR_RE.fullmatch(extension_dir_name)
    if not match:
        return extension_dir_name
    return match.group("version")


def update_config_text(
    config_text: str,
    current_root: str | None,
    extension_dir_name: str,
) -> tuple[str, bool]:
    """Replace the VS Code extension root in Codex config text.

    Args:
        config_text (str): Codex config TOML text.
        current_root (str | None): Current configured root.
        extension_dir_name (str): Installed extension directory name.

    Returns:
        tuple[str, bool]: Updated text and whether the text changed.
    """
    new_root = f"~/.vscode-server/extensions/{extension_dir_name}"
    if current_root is None:
        return config_text, False
    if current_root == new_root:
        return config_text, False

    updated_text = CONFIG_EXTENSION_ROOT_RE.sub(
        lambda match: f"{match.group('quote')}{new_root}{match.group('quote')}",
        config_text,
        count=1,
    )
    return updated_text, True


def is_stamp_fresh(stamp_path: Path, max_age_seconds: int) -> bool:
    """Check whether the update stamp is still fresh.

    Args:
        stamp_path (Path): Timestamp file path.
        max_age_seconds (int): Maximum age in seconds.

    Returns:
        bool: True when the stamp exists and is younger than max_age_seconds.
    """
    if max_age_seconds <= 0 or not stamp_path.is_file():
        return False
    return time.time() - stamp_path.stat().st_mtime < max_age_seconds


def configured_root_exists(current_root: str | None) -> bool:
    """Check whether the configured extension root exists on disk.

    Args:
        current_root (str | None): Current configured root.

    Returns:
        bool: True when the configured root exists. False when it is missing or
            no matching root is configured.
    """
    if current_root is None:
        return False
    return Path(current_root).expanduser().is_dir()


def build_parser() -> argparse.ArgumentParser:
    """Build the CLI argument parser.

    Returns:
        argparse.ArgumentParser: Configured argument parser.
    """
    script_dir = Path(__file__).resolve().parent
    cache_home = Path(os.environ.get("XDG_CACHE_HOME", "~/.cache")).expanduser()

    parser = argparse.ArgumentParser(
        description="Update Codex config.toml for the installed VS Code Codex extension.",
    )
    parser.add_argument(
        "--config",
        type=Path,
        default=script_dir / "config.toml",
        help="Codex config.toml path.",
    )
    parser.add_argument(
        "--stamp",
        type=Path,
        default=cache_home / "codex" / "vscode-extension-root.stamp",
        help="Timestamp file used to limit update frequency.",
    )
    parser.add_argument(
        "--max-age-seconds",
        type=int,
        default=24 * 60 * 60,  # 1 day
        help="Skip scans when the stamp is newer than this many seconds.",
    )
    parser.add_argument(
        "-f",
        "--force",
        action="store_true",
        help="Scan and update even when the timestamp is fresh.",
    )
    return parser


def main() -> int:
    """Run the CLI.

    Returns:
        int: Exit status code.
    """
    args = build_parser().parse_args()
    config_path = args.config.expanduser()
    stamp_path = args.stamp.expanduser()

    config_text = config_path.read_text()
    current_root = current_config_extension_root(config_text)
    if (
        not args.force
        and is_stamp_fresh(stamp_path, args.max_age_seconds)
        and configured_root_exists(current_root)
    ):
        return 0

    extension_root = Path("~/.vscode-server/extensions").expanduser()
    latest_extension_dir = find_latest_extension_dir(extension_root)
    if latest_extension_dir is None:
        warnings.warn(
            f"Warning: No Codex VS Code extension found in {extension_root}.",
            stacklevel=2,
        )
        return 0

    updated_text, changed = update_config_text(
        config_text,
        current_root,
        latest_extension_dir.name,
    )
    if changed:
        config_path.write_text(updated_text)
        before = extension_version(Path(current_root or "").name)
        after = extension_version(latest_extension_dir.name)
        print(f"Updated Codex VS Code extension root: {before} -> {after}")

    stamp_path.parent.mkdir(parents=True, exist_ok=True)
    stamp_path.touch()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
