# VScode

## launch.json

This is designed to be placed in each workspace and currently contains only Python debugging configurations.

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
