import base64
import os
import subprocess
from contextlib import suppress
from pathlib import Path

import pyperclip


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

    try:
        if "TMUX_PANE" in os.environ:
            # Pane output can lose clipboard sequences during a tmux redraw.
            client = subprocess.check_output(
                [
                    "tmux",
                    "display-message",
                    "-p",
                    "-t",
                    os.environ["TMUX_PANE"],
                    "#{client_name}",
                ],
                text=True,
            ).strip()
            subprocess.run(
                ["tmux", "set-buffer", "-w", "-t", client, "--", view_command],
                check=True,
            )
        else:
            # Base64 prevents the copied text from injecting another control sequence.
            sequence = b"\x1b]52;c;" + base64.b64encode(raw_command) + b"\x07"
            # Hooks have no controlling terminal, and stdout is reserved for JSON.
            terminal_path = os.environ.get("SSH_TTY", "/dev/tty")
            with Path(terminal_path).open("wb", buffering=0) as terminal:
                terminal.write(sequence)
    except (OSError, subprocess.CalledProcessError):
        return False
    return True
