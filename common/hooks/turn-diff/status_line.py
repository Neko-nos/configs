import json
import sys
from pathlib import Path
from typing import Any

from git_snapshot import git_cache_dir, git_worktree_root
from hook_context import read_session_status

ACTIVE_AGENT_STATES = frozenset({"working", "tool_use", "reviewing"})


def resolve_status_message(payload: dict[str, Any]) -> str | None:
    """
    Resolve the turn-diff status message for an Antigravity `statusLine` payload.

    Args:
        payload (dict[str, Any]): Parsed Antigravity status-line JSON payload.

    Returns:
        str | None: Status message to render below the default status bar, or
            None while a turn is active or when no message is available.
    """
    agent_state = payload.get("agent_state")
    if isinstance(agent_state, str) and agent_state in ACTIVE_AGENT_STATES:
        return None

    raw_session_id = payload.get("conversation_id") or payload.get("session_id")
    if not isinstance(raw_session_id, str):
        return None
    session_id = raw_session_id.strip()
    if session_id in {"", ".", ".."} or "/" in session_id or "\\" in session_id:
        return None

    raw_cwd = payload.get("cwd")
    if not isinstance(raw_cwd, str) or not raw_cwd:
        workspace = payload.get("workspace")
        if isinstance(workspace, dict):
            raw_cwd = workspace.get("current_dir") or workspace.get("project_dir")
    if not isinstance(raw_cwd, str) or not raw_cwd:
        return None

    cwd_path = Path(raw_cwd)
    if not cwd_path.is_dir():
        return None

    try:
        root = git_worktree_root(cwd_path)
    except OSError:
        return None
    if root is None:
        return None

    return read_session_status(git_cache_dir(root) / session_id)


def main() -> int:
    """
    Print the latest turn-diff status message for Antigravity's status line.

    Returns:
        int: Process exit status (always 0 so Antigravity never disables the status line).
    """
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return 0
    if not isinstance(payload, dict):
        return 0

    message = resolve_status_message(payload)
    if message is not None:
        print(message)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
