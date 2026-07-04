import argparse
import json
import shlex
import sys
from pathlib import Path

import pyperclip
from git_snapshot import (
    git_cache_dir,
    run_git,
    worktree_tree,
)
from terminal_diff import render_terminal_diff


def start_turn() -> None:
    """Capture a baseline working-tree snapshot for the current turn."""
    # ref: https://developers.openai.com/codex/hooks#common-input-fields
    payload = json.loads(sys.stdin.read())
    root = Path(
        run_git(["rev-parse", "--show-toplevel"], Path(payload["cwd"])).stdout.strip()
    )
    session_dir = git_cache_dir(root) / payload["session_id"] / payload["turn_id"]
    session_dir.mkdir(parents=True, exist_ok=True)

    tree = worktree_tree(root, session_dir / "baseline.index")
    (session_dir / "state.json").write_text(
        json.dumps({"baseline_tree": tree}, indent=2, sort_keys=True),
        encoding="utf-8",
    )


def stop_turn() -> None:
    """Save a diff from the turn baseline to the current working tree."""
    # ref: https://developers.openai.com/codex/hooks#common-input-fields
    payload = json.loads(sys.stdin.read())
    root = Path(
        run_git(["rev-parse", "--show-toplevel"], Path(payload["cwd"])).stdout.strip()
    )
    session_dir = git_cache_dir(root) / payload["session_id"] / payload["turn_id"]
    state_path = session_dir / "state.json"
    state = json.loads(state_path.read_text(encoding="utf-8"))

    current_tree = worktree_tree(root, session_dir / "current.index")
    baseline_tree = str(state["baseline_tree"])
    diff = run_git(
        ["diff", "--binary", "--find-renames", baseline_tree, current_tree],
        root,
    )
    if diff.returncode not in (0, 1):
        raise RuntimeError(diff.stderr.strip() or "Codex turn diff failed")

    terminal_diff_path = session_dir / "last-turn.ansi"
    terminal_diff_path.write_text(
        render_terminal_diff(diff.stdout),
        encoding="utf-8",
    )
    view_command = shlex.join(["less", "-R", str(terminal_diff_path)])
    pyperclip.copy(view_command)

    if diff.stdout == "":
        print(
            json.dumps(
                {
                    "continue": True,
                    "systemMessage": (
                        "Codex turn diff: no file changes.\n"
                        f"Terminal diff: {terminal_diff_path}"
                    ),
                },
            ),
        )
        return

    stat = run_git(["diff", "--stat", baseline_tree, current_tree], root)
    print(f"Terminal diff: {terminal_diff_path}", file=sys.stderr)
    if stat.stdout.strip():
        print(stat.stdout, end="", file=sys.stderr)
    print(
        json.dumps(
            {"continue": True, "systemMessage": f"Terminal diff: {terminal_diff_path}"}
        )
    )


def main() -> int:
    """
    Run the turn diff hook.

    Returns:
        int: Process exit status.
    """
    parser = argparse.ArgumentParser(description="Capture Codex turn diffs.")
    parser.add_argument("command", choices=("start", "stop"))
    args = parser.parse_args()

    if args.command == "start":
        start_turn()
    else:
        stop_turn()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
