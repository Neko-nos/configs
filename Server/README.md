# Rootless Server Setup

This setup is for Linux servers where you cannot get root privileges. It uses
Zsh on ordinary servers and Bash on Slurm-managed login or head nodes.
Tools that are not provided by the server are installed without root access.
Spack manages command-line packages and their dependencies in an isolated
environment under `~/spack/var/spack/environments/server`.

## Installation

Run [install.sh](./install/install.sh) to detect the server type, install and
configure the selected shell, and optionally set up Git, GitHub SSH, nano, and
Codex CLI:

```bash
bash Server/install/install.sh
```

The installer clones the latest Spack release when needed, detects compatible
host packages and compilers, then installs the targets declared in
[spack.yaml](./spack.yaml). The environment view exposes only the requested
commands through the Server shell profiles; build and runtime dependencies
remain isolated. A system C/C++ compiler and Spack's other
[prerequisites](https://spack.readthedocs.io/en/latest/installing_prerequisites.html)
must already be available because this setup does not have administrator access.

The committed `spack.lock` records the concrete dependency graph. To install
changes made to the manifest, run:

```bash
spack -e server install
```

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
