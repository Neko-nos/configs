import os
import subprocess
from pathlib import Path


def run_git(
    args: list[str],
    cwd: Path,
    env: dict[str, str] | None = None,
) -> subprocess.CompletedProcess[str]:
    """
    Run a Git command and return the completed process.

    Args:
        args (list[str]): Git arguments, excluding the `git` executable.
        cwd (Path): Directory where Git should run.
        env (dict[str, str] | None): Optional environment override.

    Returns:
        subprocess.CompletedProcess[str]: The completed Git process.
    """
    return subprocess.run(
        ["git", *args],
        cwd=cwd,
        env=env,
        text=True,
        capture_output=True,
        check=False,
    )


def git_cache_dir(root: Path) -> Path:
    """
    Return the Git metadata cache directory for turn diff artifacts.

    Args:
        root (Path): Git repository root.

    Returns:
        Path: Git metadata cache directory.
    """
    git_path = run_git(["rev-parse", "--git-path", "codex-turn-diff"], root)
    return root / Path(git_path.stdout.strip())


def git_worktree_root(cwd: Path) -> Path | None:
    """
    Return the Git worktree root for a directory, if one exists.

    Args:
        cwd (Path): Directory to inspect.

    Returns:
        Path | None: Git worktree root, or None outside a Git worktree.
    """
    root = run_git(["rev-parse", "--show-toplevel"], cwd)
    if root.returncode != 0:
        return None
    return Path(root.stdout.strip())


def worktree_tree(root: Path, index_path: Path) -> str:
    """
    Write the current working tree state to a Git tree object.

    Args:
        root (Path): Git repository root.
        index_path (Path): Temporary index file path.

    Returns:
        str: Git tree object ID.
    """
    env = os.environ.copy()
    env["GIT_INDEX_FILE"] = str(index_path)

    head = run_git(["rev-parse", "--verify", "HEAD"], root, env=env)
    treeish = "HEAD" if head.returncode == 0 else "--empty"
    run_git(["read-tree", treeish], root, env=env)

    run_git(["add", "-A", "--", "."], root, env=env)
    tree = run_git(["write-tree"], root, env=env)
    return tree.stdout.strip()


def write_turn_patch(
    root: Path, baseline_tree: str, current_tree: str, patch_path: Path
) -> None:
    """
    Write a reversible Git patch between two working tree snapshots.

    Args:
        root (Path): Git repository root.
        baseline_tree (str): Working tree snapshot before the turn.
        current_tree (str): Working tree snapshot after the turn.
        patch_path (Path): Destination for the patch.
    """
    # Keep the original bytes so CRLF and non-UTF-8 files can be restored exactly.
    with patch_path.open("wb") as patch:
        subprocess.run(
            [
                "git",
                "diff",
                "--binary",
                "--find-renames",
                "--no-ext-diff",
                "--no-textconv",
                "--no-color",
                "--src-prefix=a/",
                "--dst-prefix=b/",
                baseline_tree,
                current_tree,
                "--",
            ],
            cwd=root,
            stdout=patch,
            stderr=subprocess.PIPE,
            check=True,
        )
