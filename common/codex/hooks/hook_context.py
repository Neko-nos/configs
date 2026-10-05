import json
import sys
from pathlib import Path

from git_snapshot import git_cache_dir, git_worktree_root


def is_cli_session(transcript_path: str | None) -> bool:
    """
    Return whether a Codex transcript belongs to a CLI session.

    Args:
        transcript_path (str | None): Path to the Codex session transcript.

    Returns:
        bool: Whether the session was started from the CLI.
    """
    if transcript_path is None:
        return False

    with Path(transcript_path).open(encoding="utf-8") as transcript:
        metadata = json.loads(transcript.readline())
    # Codex names the TUI client codex-tui and sets codex_exec as the exec originator.
    # ref: https://github.com/openai/codex/blob/8b8fa7276f3da289108512d673303eeacc5bcff3/codex-rs/tui/src/lib.rs#L562
    # ref: https://github.com/openai/codex/blob/8b8fa7276f3da289108512d673303eeacc5bcff3/codex-rs/exec/src/lib.rs#L241
    return metadata["payload"]["originator"] in {
        "codex-tui",
        "codex_exec",
    }


def read_hook_context() -> tuple[Path, Path] | None:
    """
    Read the repository and turn directory from a CLI hook's input.

    Returns:
        tuple[Path, Path] | None: Repository root and turn directory, or None
            outside a CLI session with a Git working tree.
    """
    # ref: https://developers.openai.com/codex/hooks#common-input-fields
    payload = json.load(sys.stdin)
    if not is_cli_session(payload["transcript_path"]):
        return None

    root = git_worktree_root(Path(payload["cwd"]))
    if root is None:
        return None

    turn_dir = git_cache_dir(root) / payload["session_id"] / payload["turn_id"]
    return root, turn_dir
