from hook_context import (
    clear_session_status,
    read_hook_context,
    resolve_capture_turn_dir,
    write_active_turn,
)
from turn_store import capture_baseline


def main() -> int:
    """
    Capture the working tree before a CLI turn starts.

    Returns:
        int: Process exit status.
    """
    agent, context = read_hook_context()
    if context is not None:
        turn_dir = resolve_capture_turn_dir(context)
        if turn_dir is not None:
            capture_baseline(context.root, turn_dir)
            if context.agent == "antigravity":
                write_active_turn(context.session_dir, turn_dir.name)
                clear_session_status(context.session_dir)
    if agent == "antigravity":
        print("{}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
