# macOS setup

## Installation

This runs every install scripts.

```console
zsh Mac/install/install.sh
```

## Fonts and Apple Terminal

Install [MesloLGS NF](https://github.com/romkatv/powerlevel10k#fonts) for prompt icons:

```console
zsh Mac/install/fonts.sh
```

To import and select the supplied Apple Terminal profile, run:

```console
zsh Mac/install/terminal.sh
```

## Clipboard history

[Clipy](https://clipy-app.com/) lets you reuse earlier clipboard contents and saved text snippets.

```console
zsh Mac/install/clipy.sh
```

After setup, import `Mac/clipy/snippets.xml` from Clipy's **Manage Snippets**
window to use the supplied snippets.

## Keyboard shortcuts

[Karabiner-Elements](https://karabiner-elements.pqrs.org/) adds text editing shortcuts across apps, including
Emacs-style shortcuts.

```console
zsh Mac/install/karabiner_elements.sh
```

Choose `jis` for a Japanese JIS keyboard, or `us` for a US keyboard that should use
the supplied JIS-style mappings.

## Hammerspoon

[Hammerspoon](https://www.hammerspoon.org/) configuration:

| File | Purpose |
| --- | --- |
| [init.lua](hammerspoon/init.lua) | Starts Hammerspoon at login and loads the other scripts. |
| [terminal_selection.lua](hammerspoon/terminal_selection.lua) | Lets you select text in Terminal with **Option-drag**, even when an app handles mouse input. |
| [terminal_copy.lua](hammerspoon/terminal_copy.lua) | Lets you copy selected text in Terminal or [tmux](https://github.com/tmux/tmux) with **Command+C**. |
| [terminal_undo.lua](hammerspoon/terminal_undo.lua) | Makes **Command+Z** undo edits in nano when using Terminal. |
| [terminal_shortcut.lua](hammerspoon/terminal_shortcut.lua) | Handles key remapping for copy and undo in Terminal. |
| [finder_paste.lua](hammerspoon/finder_paste.lua) | Lets you paste clipboard images into Finder as PNG files with **Command+V**. |
| [vscode_browser.lua](hammerspoon/vscode_browser.lua) | Uses the supplied [Browser Click Routing](../VSCode/extensions/browser-click-routing/README.md) extension to open links inside VS Code with **Command-click** or in your default browser with **Ctrl-click**. |

Install:

```console
zsh Mac/install/hammerspoon.sh
```
