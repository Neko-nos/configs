from hook_context import read_hook_context
from turn_store import capture_baseline


def main() -> int:
    """
    Capture the working tree before a CLI turn starts.

    Returns:
        int: Process exit status.
    """
    context = read_hook_context()
    if context is not None:
        root, turn_dir = context
        capture_baseline(root, turn_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
