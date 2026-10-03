import json
import shlex
from pathlib import Path

from clipboard import copy_view_command
from hook_context import read_hook_context
from turn_store import save_turn_diff


def save_turn() -> str | None:
    """
    Save the completed turn's review and copy its viewer command.

    Returns:
        str | None: Status message, or None when no baseline is available.
    """
    context = read_hook_context()
    if context is None:
        return None

    root, turn_dir = context
    state_path = turn_dir / "state.json"
    if not state_path.exists():
        return None

    manifest_path = save_turn_diff(root, turn_dir)
    if manifest_path is None:
        return "Codex turn diff: no file changes."

    home = Path.home()
    viewer_path = (
        Path(__file__).with_name("terminal_diff_viewer.py").resolve().relative_to(home)
    )
    manifest_path = manifest_path.resolve().relative_to(home)
    view_command = (
        f"python ~/{shlex.quote(str(viewer_path))} "
        f"--manifest ~/{shlex.quote(str(manifest_path))}"
    )
    copied = copy_view_command(view_command)

    return (
        "Codex turn diff: viewer command sent to clipboard."
        if copied
        else "Codex turn diff: could not send viewer command to clipboard."
    )


def main() -> int:
    """
    Save the turn and emit its hook response.

    Returns:
        int: Process exit status.
    """
    message = save_turn()
    response = {"continue": True}
    if message is not None:
        response["systemMessage"] = message
    print(json.dumps(response))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
