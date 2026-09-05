# VScode

## launch.json

This is designed to be placed in each workspace and currently contains only Python debugging configurations.

## linebreak.py

In VSCode's `settings.json`, you can set `"markdown.preview.breaks": true`. While this allows line breaks to display correctly in the preview, they are not reflected in the code itself.\
Since typing a trailing backslash manually every time is tedious, I created a script that automatically inserts one to handle line breaks appropriately upon saving.\
It is implemented using only the Python standard library, so it works on the system Python.

> [!NOTE]
> Currently, Markdown files relying heavily on HTML are not supported.

### Run tests

From the repository root:

```console
PYTHONPATH=. uv run pytest VSCode/test_linebreak.py
```

## settings.json

The shared `settings.json` for VSCode.

## keybindings.json

The `keybindings.json` for VSCode. In the integrated terminal, Shift+Enter
sends a bracketed-paste newline (`\u001b[200~\n\u001b[201~`). This lets Codex CLI
insert a newline without submitting the prompt through local or Remote SSH tmux sessions.
Cmd+C copies a tmux mouse selection without making mouse release copy it automatically.
Cmd+V uses the local Smart Terminal Paste extension to paste text normally or send
Ctrl+V when the macOS clipboard contains an image, allowing Codex CLI to attach it.
In a Remote SSH workspace, the extension instead writes the clipboard image to the
remote `/tmp` directory and pastes its server-side path into Codex.
