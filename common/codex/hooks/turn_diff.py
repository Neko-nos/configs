from hook_context import read_hook_context
from prune_turns import prune_diff_sessions, retention_parser
from save_turn import main as save_turn
from turn_store import capture_baseline


def main() -> int:
    """
    Handle the hook commands still loaded by an active Codex session.

    Returns:
        int: Process exit status.
    """
    # Active sessions can keep invoking this path after hooks.json changes.
    parser = retention_parser("Run previously loaded turn hooks.")
    parser.add_argument("command", choices=("start", "stop"))
    args = parser.parse_args()
    if args.command == "stop":
        return save_turn()

    context = read_hook_context()
    if context is not None:
        root, turn_dir = context
        capture_baseline(root, turn_dir)
        prune_diff_sessions(turn_dir, args.retention_days)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
