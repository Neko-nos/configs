import json
import shlex
from pathlib import Path

from clipboard import copy_view_command
from hook_context import (
    HookContext,
    read_hook_context,
    resolve_stop_turn_dir,
    write_session_status,
)
from turn_store import save_turn_diff


def save_turn(context: HookContext | None) -> str | None:
    """
    Save the completed turn's review and copy its viewer command.

    Args:
        context (HookContext | None): Resolved hook context.

    Returns:
        str | None: Status message, or None when no baseline is available.
    """
    if context is None:
        return None

    turn_dir = resolve_stop_turn_dir(context)
    if turn_dir is None:
        return None

    state_path = turn_dir / "state.json"
    if not state_path.exists():
        return None

    manifest_path = save_turn_diff(context.root, turn_dir)
    if manifest_path is None:
        return "Turn diff: no file changes."

    home = Path.home()
    viewer_path = (
        Path(__file__).with_name("terminal_diff_viewer.py").resolve().relative_to(home)
    )
    manifest_path = manifest_path.resolve()
    manifest_arg = (
        f"~/{shlex.quote(str(manifest_path.relative_to(home)))}"
        if manifest_path.is_relative_to(home)
        else shlex.quote(str(manifest_path))
    )
    view_command = f"python ~/{shlex.quote(str(viewer_path))} --manifest {manifest_arg}"
    copied = copy_view_command(view_command)

    return (
        "Turn diff: viewer command sent to clipboard."
        if copied
        else "Turn diff: could not send viewer command to clipboard."
    )


def main() -> int:
    """
    Save the turn and emit its hook response.

    Returns:
        int: Process exit status.
    """
    agent, context = read_hook_context()
    message = save_turn(context)
    if agent == "antigravity":
        if context is not None and message is not None:
            write_session_status(context.session_dir, message)
        print(json.dumps({"decision": "allow"}))
        return 0

    response: dict[str, object] = {"continue": True}
    if message is not None:
        response["systemMessage"] = message
    print(json.dumps(response))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
