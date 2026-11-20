import argparse
import shutil
import time
from contextlib import suppress
from datetime import timedelta
from pathlib import Path

from hook_context import read_hook_context


def prune_diff_sessions(session_dir: Path, retention_days: int) -> None:
    """
    Remove inactive saved sessions while preserving the current session.

    Args:
        session_dir (Path): Current session directory within the cache root.
        retention_days (int): Number of inactive days to retain saved sessions.
    """
    cache_dir = session_dir.parent
    current_session_id = session_dir.name
    cutoff = time.time() - timedelta(days=retention_days).total_seconds()
    # Same-event hooks may run concurrently, so baseline capture may not have run yet.
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


def main() -> int:
    """
    Prune inactive sessions independently of baseline capture.

    Returns:
        int: Process exit status.
    """
    parser = argparse.ArgumentParser(description="Prune saved turn reviews.")
    parser.add_argument(
        "-r",
        "--retention-days",
        type=int,
        default=30,
        help="prune other sessions after this many inactive days (default: 30)",
    )
    args = parser.parse_args()
    agent, context = read_hook_context()
    if context is not None:
        prune_diff_sessions(context.session_dir, args.retention_days)
    if agent == "antigravity":
        print("{}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
