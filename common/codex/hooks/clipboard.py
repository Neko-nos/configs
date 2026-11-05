import os
import subprocess
from contextlib import suppress

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
        # Daemons can start before tmux, so inherited terminal variables are unreliable.
        client = subprocess.check_output(
            ["tmux", "display-message", "-p", "#{client_name}"],
            text=True,
        ).strip()
        # set-buffer succeeds without delivering to a clipboard if no client exists.
        if not client:
            return False
        # Pane output can lose clipboard sequences during a tmux redraw.
        subprocess.run(
            ["tmux", "set-buffer", "-w", "-t", client, "--", view_command],
            check=True,
        )
    except (OSError, subprocess.CalledProcessError):
        return False
    return True
