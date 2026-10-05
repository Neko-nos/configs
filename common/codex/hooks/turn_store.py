import fcntl
import json
from pathlib import Path

from git_snapshot import run_git, worktree_tree, write_turn_patch
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
        json.dumps({"baseline_tree": tree}, indent=2),
        encoding="utf-8",
    )


def save_turn_diff(root: Path, turn_dir: Path) -> Path | None:
    """
    Save the turn's patch, rendered diffs, and viewer manifest.

    Args:
        root (Path): Git repository root.
        turn_dir (Path): Directory containing the captured baseline.

    Returns:
        Path | None: Manifest path, or None when the turn has no file changes.
    """
    state = json.loads((turn_dir / "state.json").read_text(encoding="utf-8"))
    current_tree = worktree_tree(root, turn_dir / "current.index")
    patch_path = turn_dir / "last-turn.patch"
    write_turn_patch(root, state["baseline_tree"], current_tree, patch_path)
    if patch_path.stat().st_size == 0:
        return None

    rendered_files = render_terminal_diff_files(
        patch_path.read_text(encoding="utf-8", errors="replace")
    )
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
        json.dumps(
            {
                "root": str(root),
                "patch": str(patch_path),
                "applied": True,
                "files": entries,
            },
            indent=2,
        ),
        encoding="utf-8",
    )
    return manifest_path


def apply_turn(manifest_path: Path, *, reverse: bool) -> str:
    """
    Undo or reapply a saved turn without changing the staging area.

    Args:
        manifest_path (Path): Saved turn manifest, including its patch and state.
        reverse (bool): Whether to undo instead of reapply the turn.

    Returns:
        str: Status message describing the completed action.

    Raises:
        RuntimeError: Git cannot apply the complete patch to the working tree.
    """
    # Serialize viewers so repeated key presses cannot apply a turn twice.
    with manifest_path.open("r+", encoding="utf-8") as manifest_file:
        fcntl.flock(manifest_file, fcntl.LOCK_EX)
        manifest = json.load(manifest_file)
        state = "undone" if reverse else "applied"
        if manifest["applied"] != reverse:
            return f"Turn changes already {state}."

        args = ["apply", "--whitespace=nowarn"]
        if reverse:
            args.append("--reverse")
        args.extend(["--", manifest["patch"]])
        # Without --reject Git refuses the whole patch if any hunk conflicts.
        result = run_git(args, Path(manifest["root"]))
        if result.returncode != 0:
            raise RuntimeError(result.stderr.strip() or "Could not apply turn changes.")

        manifest["applied"] = not reverse
        manifest_file.seek(0)
        json.dump(manifest, manifest_file, indent=2)
        manifest_file.truncate()
    return f"Turn changes {state}."
