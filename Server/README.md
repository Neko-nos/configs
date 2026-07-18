# Rootless Server Setup

This setup is for Linux servers where you cannot get root privileges. It uses
Zsh on ordinary servers and Bash on Slurm-managed login or head nodes.
Tools that are not provided by the server are installed under `~/.local`.

## Installation

Run [install.sh](./install/install.sh) to detect the server type, install and
configure the selected shell, and optionally set up Git, GitHub SSH, nano, and
Codex CLI:

```bash
bash Server/install/install.sh
```

To check for the updates of installed commands, run [commands.sh](./install/commands.sh)
again.

## Bash Features

[.bashrc](./bash/.bashrc) configures the interactive shell.

- Recreates as much of the [.zshrc](../common/zsh/.zshrc) option behavior as
  Bash can support directly.
- Shares command history across SSH sessions.
- `Ctrl-P` works like Zsh's recent-directory search and changes to the selected
  directory immediately. Bash keeps a separate recent-directory list and does
  not use the current command line as the initial search query.
- `Ctrl-R` works like Zsh's multiline history search and inserts the selection
  without running it.
