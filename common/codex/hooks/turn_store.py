import json
from pathlib import Path

from git_snapshot import run_git, worktree_tree
from terminal_diff import render_terminal_diff_files


def capture_baseline(root: Path, turn_dir: Path) -> None:
    """
    Save the turn's initial snapshot.

    Args:
        root (Path): Git repository root.
        turn_dir (Path): Directory for this turn within its session directory.
    """
    turn_dir.mkdir(parents=True, exist_ok=True)
    state_path = turn_dir / "state.json"
    # Mid-turn replies can trigger UserPromptSubmit again with the same turn ID.
    if state_path.exists():
        return

    tree = worktree_tree(root, turn_dir / "baseline.index")
    state_path.write_text(
        json.dumps({"baseline_tree": tree}, indent=2, sort_keys=True),
        encoding="utf-8",
    )


def save_turn_diff(root: Path, turn_dir: Path) -> Path | None:
    """
    Save the turn's rendered diffs and viewer manifest.

    Args:
        root (Path): Git repository root.
        turn_dir (Path): Directory containing the captured baseline.

    Returns:
        Path | None: Manifest path, or None when the turn has no file changes.
    """
    state = json.loads((turn_dir / "state.json").read_text(encoding="utf-8"))
    current_tree = worktree_tree(root, turn_dir / "current.index")
    baseline_tree = str(state["baseline_tree"])
    diff = run_git(
        ["diff", "--binary", "--find-renames", baseline_tree, current_tree],
        root,
    )
    if diff.returncode not in (0, 1):
        raise RuntimeError(diff.stderr.strip() or "Codex turn diff failed")
    if diff.stdout == "":
        return None

    rendered_files = render_terminal_diff_files(diff.stdout)
    manifest_path = turn_dir / "last-turn.json"
    entries = []
    for index, (display_path, rendered, added, removed) in enumerate(
        rendered_files, start=1
    ):
        file_path = turn_dir / f"last-turn-{index}.ansi"
        file_path.write_text(rendered, encoding="utf-8")
        entries.append(
            {
                "title": display_path or "unknown",
                "path": str(file_path),
                "added": added,
                "removed": removed,
            }
        )
    manifest_path.write_text(
        json.dumps(entries, indent=2),
        encoding="utf-8",
    )
    return manifest_path
