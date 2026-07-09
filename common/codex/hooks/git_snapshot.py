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
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
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
    inside_worktree = run_git(["rev-parse", "--is-inside-work-tree"], cwd)
    if inside_worktree.returncode != 0 or inside_worktree.stdout.strip() != "true":
        return None

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
    if head.returncode == 0:
        run_git(["read-tree", "HEAD"], root, env=env)
    else:
        run_git(["read-tree", "--empty"], root, env=env)

    run_git(["add", "-A", "--", "."], root, env=env)
    tree = run_git(["write-tree"], root, env=env)
    return tree.stdout.strip()
