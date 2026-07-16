# Rootless Server Setup

This setup is for Linux servers where you cannot get root privileges. It
recreates the minimum useful parts of this repository's Zsh environment with
Bash and user-local tools.

## Installation

Run [install.sh](./install/install.sh) to install commands, build useful
commands from source, link the Bash configuration, and optionally set up Git,
GitHub SSH, nano, and Codex CLI:

```bash
bash Server/install/install.sh
```

[commands.sh](./install/commands.sh) avoids root access by downloading
standalone binaries into your home directory and installing Python CLI tools
with `uv tool install`.

To check for the updates of installed commands, run [commands.sh](./install/commands.sh)
again.

[codex.sh](./install/codex.sh) installs Codex CLI and the commands it needs
without root privileges. It currently installs:

- `bwrap`, extracted from Ubuntu's `bubblewrap` package into `~/.local/bin`
- Codex CLI, using the official Codex installer with `CODEX_INSTALL_DIR` set to
  `~/.local/bin`
- Codex configuration links in `~/.codex`, including Rustup from
  [rust.sh](../common/install/rust.sh) for hook tools that use Rust

[build_cmds.sh](./install/build_cmds.sh) builds source-only tools into
`~/.local`. It currently installs:

- `ncurses`
- `nano`
- `tree`

Building source packages still requires normal build tools such as a compiler
and `make` to already be available on the server. If they are missing, the
build will fail and you need to use the system commands or ask the server
administrator to provide the build tools.

[bash.sh](./install/bash.sh) links [.bash_profile](./bash/.bash_profile) and
[.bashrc](./bash/.bashrc) into `$HOME`.

[git.sh](../common/install/git.sh) creates `~/.gitconfig` with your GitHub
email and username, includes the shared repository Git settings, and links the
shared global Git ignore file.

[github_ssh.sh](../common/install/github_ssh.sh) creates or reuses an Ed25519
SSH key, adds it to `ssh-agent`, configures `github.com` in `~/.ssh/config`,
and either adds the public key with GitHub CLI or prints manual setup
instructions.

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
