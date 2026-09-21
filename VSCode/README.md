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

| Area | Function |
| --- | --- |
| Editor | Emacs-style navigation and editing. |
| Integrated terminal | Multiline Codex prompts, selection copying, and tmux shortcuts. |
| Markdown preview | Refresh the preview. |

## Local extensions

- **Browser Click Routing:** Cmd+click opens web links in VSCode's integrated browser; Ctrl+click opens your default external browser.
- **Smart Terminal Paste:** Cmd+V pastes text or attaches clipboard images to Codex CLI in the integrated terminal. Remote SSH is supported.

Install from the repository root:

```console
zsh Mac/install/vscode.sh
zsh Mac/install/hammerspoon.sh
```
