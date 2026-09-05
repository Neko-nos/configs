import argparse
import base64
import json
import os
import shlex
import sys
from contextlib import suppress
from pathlib import Path

import pyperclip

from git_snapshot import (
    git_cache_dir,
    git_worktree_root,
    run_git,
    worktree_tree,
)
from terminal_diff import render_terminal_diff_files


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


def copy_view_command(view_command: str) -> bool:
    """
    Copy a terminal diff command when a clipboard provider is available.

    Args:
        view_command (str): Command to copy.

    Returns:
        bool: Whether the command was sent to a clipboard provider.
    """
    remote_session = "SSH_TTY" in os.environ or "SSH_CONNECTION" in os.environ
    if not remote_session:
        with suppress(OSError, pyperclip.PyperclipException):
            pyperclip.copy(view_command)
            return True

    raw_command = view_command.encode()
    # The expected command is short; the limit avoids flooding the terminal.
    if len(raw_command) > 1_000:
        return False

    # Base64 prevents the copied text from injecting another control sequence;
    # tmux relays OSC 52 from its pane when set-clipboard is on.
    sequence = b"\x1b]52;c;" + base64.b64encode(raw_command) + b"\x07"
    # Stop-hook stdout is reserved for JSON, so the sequence must bypass it.
    try:
        with Path("/dev/tty").open("wb", buffering=0) as terminal:
            terminal.write(sequence)
    except OSError:
        return False
    return True


def start_turn() -> None:
    """Capture a baseline working-tree snapshot for the current turn."""
    # ref: https://developers.openai.com/codex/hooks#common-input-fields
    payload = json.loads(sys.stdin.read())
    if not is_cli_session(payload["transcript_path"]):
        return

    root = git_worktree_root(Path(payload["cwd"]))
    if root is None:
        return

    session_dir = git_cache_dir(root) / payload["session_id"] / payload["turn_id"]
    session_dir.mkdir(parents=True, exist_ok=True)

    tree = worktree_tree(root, session_dir / "baseline.index")
    (session_dir / "state.json").write_text(
        json.dumps({"baseline_tree": tree}, indent=2, sort_keys=True),
        encoding="utf-8",
    )


def stop_turn() -> None:
    """Save a diff from the turn baseline to the current working tree."""
    # ref: https://developers.openai.com/codex/hooks#common-input-fields
    payload = json.loads(sys.stdin.read())
    if not is_cli_session(payload["transcript_path"]):
        print(json.dumps({"continue": True}))
        return

    root = git_worktree_root(Path(payload["cwd"]))
    if root is None:
        print(json.dumps({"continue": True}))
        return

    session_dir = git_cache_dir(root) / payload["session_id"] / payload["turn_id"]
    state_path = session_dir / "state.json"
    if not state_path.exists():
        print(json.dumps({"continue": True}))
        return

    state = json.loads(state_path.read_text(encoding="utf-8"))

    current_tree = worktree_tree(root, session_dir / "current.index")
    baseline_tree = str(state["baseline_tree"])
    diff = run_git(
        ["diff", "--binary", "--find-renames", baseline_tree, current_tree],
        root,
    )
    if diff.returncode not in (0, 1):
        raise RuntimeError(diff.stderr.strip() or "Codex turn diff failed")

    if diff.stdout == "":
        print(
            json.dumps(
                {
                    "continue": True,
                    "systemMessage": "Codex turn diff: no file changes.",
                },
            ),
        )
        return

    rendered_files = render_terminal_diff_files(diff.stdout)
    manifest_path = session_dir / "last-turn.json"
    manifest = []
    for index, (display_path, rendered, added, removed) in enumerate(
        rendered_files, start=1
    ):
        file_path = session_dir / f"last-turn-{index}.ansi"
        file_path.write_text(rendered, encoding="utf-8")
        manifest.append(
            {
                "title": display_path or "unknown",
                "path": str(file_path),
                "added": added,
                "removed": removed,
            }
        )
    manifest_path.write_text(
        json.dumps(manifest, indent=2),
        encoding="utf-8",
    )
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

    print(
        json.dumps(
            {
                "continue": True,
                "systemMessage": (
                    "Codex turn diff: viewer command sent to clipboard."
                    if copied
                    else "Codex turn diff: could not send viewer command to clipboard."
                ),
            }
        )
    )


def main() -> int:
    """
    Run the turn diff hook.

    Returns:
        int: Process exit status.
    """
    parser = argparse.ArgumentParser(description="Capture Codex turn diffs.")
    parser.add_argument("command", choices=("start", "stop"))
    args = parser.parse_args()

    if args.command == "start":
        start_turn()
    else:
        stop_turn()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
