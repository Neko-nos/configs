import json
import shlex
import sys
from pathlib import Path
from typing import Any

from clipboard import copy_view_command
from hook_context import HookContext, parse_hook_context, resolve_stop_turn_dir
from turn_store import save_turn_diff


def is_final_antigravity_invocation(transcript_path: str | None) -> bool:
    """
    Return whether the latest transcript entry ended the turn without tool calls.

    Args:
        transcript_path (str | None): Path to the Antigravity `transcript.jsonl`.

    Returns:
        bool: True when the last non-empty entry is a `PLANNER_RESPONSE` with no
            `tool_calls`.
    """
    if not transcript_path:
        return False
    path = Path(transcript_path).expanduser()
    if not path.is_file():
        return False

    last_line = ""
    with path.open(encoding="utf-8") as transcript:
        for line in transcript:
            stripped = line.strip()
            if stripped:
                last_line = stripped
    if not last_line:
        return False

    try:
        step = json.loads(last_line)
    except json.JSONDecodeError:
        return False
    return step.get("type") == "PLANNER_RESPONSE" and not step.get("tool_calls")


def is_antigravity_post_invocation(payload: dict[str, Any]) -> bool:
    """
    Return whether an Antigravity payload came from a `PostInvocation` hook.

    Args:
        payload (dict[str, Any]): Parsed hook JSON payload from stdin.

    Returns:
        bool: True for `PostInvocation`, False for `Stop`.
    """
    event_name = payload.get("hookEventName")
    if event_name == "PostInvocation":
        return True
    if event_name == "Stop":
        return False
    return "terminationReason" not in payload and "fullyIdle" not in payload


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
    payload = json.load(sys.stdin)
    agent, context = parse_hook_context(payload)
    if agent == "antigravity":
        if is_antigravity_post_invocation(payload):
            if context is None or not is_final_antigravity_invocation(
                context.transcript_path
            ):
                print("{}")
                return 0

            message = save_turn(context)
            if message is None:
                print("{}")
                return 0

            print(
                json.dumps(
                    {
                        "injectSteps": [
                            {
                                "systemMessage": {
                                    "systemMessage": "",
                                    "metadata": {"user_markdown": message},
                                }
                            }
                        ]
                    }
                )
            )
            return 0

        save_turn(context)
        print(json.dumps({"decision": "allow"}))
        return 0

    message = save_turn(context)
    response: dict[str, object] = {"continue": True}
    if message is not None:
        response["systemMessage"] = message
    print(json.dumps(response))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
