# Rootless Server Setup

This setup is for Linux servers where you cannot get root privileges. It
recreates the minimum useful parts of this repository's Zsh environment with
Bash and user-local tools.

## Installation

Run [install.sh](./install/install.sh) to install commands and link the Bash
and nano configuration:

```bash
bash Server/install/install.sh
```

[commands.sh](./install/commands.sh) avoids root access by downloading
standalone binaries into your home directory and installing Python CLI tools
with `uv tool install`. Currently it installs:

- `uv` and `uvx`
- `gdown`
- `shellcheck`

[bash.sh](./install/bash.sh) links [.bash_profile](./bash/.bash_profile) and
[.bashrc](./bash/.bashrc) into `$HOME`.

[nano.sh](./install/nano.sh) links nano syntax files and the custom
`~/nanorc/.nanorc` configuration into the server-side home directory.

## Bash Features

[.bashrc](./bash/.bashrc) configures the interactive shell.

- Recreates as much of the [.zshrc](../common/zsh/.zshrc) option behavior as
  Bash can support directly, including history, glob, completion, and key
  settings.
- Loads [aliases.sh](./bash/aliases.sh), [functions.sh](./bash/functions.sh),
  and [prompt.sh](./bash/prompt.sh).
- Shares command history across SSH sessions.
- Shows Git branch information in the prompt.
- Expands repeated dots while editing commands, so `...` becomes `../..`.

[aliases.sh](./bash/aliases.sh) adds compact defaults for `ls`, `tree`, and
colored `grep`.

[functions.sh](./bash/functions.sh) provides `ruff-fix` and the Bash version of
the Zsh repeated-dot path expansion.

[prompt.sh](./bash/prompt.sh) enables Git branch information in the prompt. It
uses `~/git-prompt.sh`, and downloads it with `wget` if it is missing.
