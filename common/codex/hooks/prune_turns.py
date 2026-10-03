import argparse
import shutil
import time
from contextlib import suppress
from datetime import timedelta
from pathlib import Path

from hook_context import read_hook_context


def prune_diff_sessions(turn_dir: Path, retention_days: int) -> None:
    """Remove inactive saved sessions while preserving the current session.

    Args:
        turn_dir (Path): Current turn's directory within its session directory.
        retention_days (int): Number of inactive days to retain saved sessions.
    """
    cache_dir = turn_dir.parent.parent
    current_session_id = turn_dir.parent.name
    cutoff = time.time() - timedelta(days=retention_days).total_seconds()
    # Same-event hooks run concurrently, so baseline capture may not have run yet.
    cache_dir.mkdir(parents=True, exist_ok=True)
    for session in cache_dir.iterdir():
        if session.name == current_session_id:
            continue

        # Another session's hook may finish pruning the same files first.
        with suppress(FileNotFoundError):
            # Edits within a turn do not update the parent session directory's mtime.
            if session.stat().st_mtime < cutoff and all(
                path.lstat().st_mtime < cutoff for path in session.rglob("*")
            ):
                shutil.rmtree(session)


def retention_parser(description: str) -> argparse.ArgumentParser:
    """
    Build the parser shared by the cleanup and legacy hooks.

    Args:
        description (str): Description shown in command help.

    Returns:
        argparse.ArgumentParser: Parser with the retention option.
    """
    parser = argparse.ArgumentParser(description=description)
    parser.add_argument(
        "-r",
        "--retention-days",
        type=int,
        default=30,
        help="prune other sessions after this many inactive days (default: 30)",
    )
    return parser


def main() -> int:
    """
    Prune inactive sessions independently of baseline capture.

    Returns:
        int: Process exit status.
    """
    parser = retention_parser("Prune saved Codex turn reviews.")
    args = parser.parse_args()
    context = read_hook_context()
    if context is None:
        return 0

    _, turn_dir = context
    prune_diff_sessions(turn_dir, args.retention_days)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
