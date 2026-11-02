# Neko-nos's dotfiles & configs

Personal settings for a consistent development environment on macOS, Ubuntu,
and WSL, with keyboard settings for Windows and a Linux server setup.

## Installation

> [!IMPORTANT]
> If you want to use these dotfiles, review and customize the code.
> **Do not blindly use my settings unless you understand what they do.**
> In fact, some settings are system-level (e.g., key configurations).

Clone into `~/configs`:

```console
git clone https://github.com/Neko-nos/configs.git ~/configs
```

Follow the setup for your platform and choose optional tools when prompted:

| Platform | Setup |
| --- | --- |
| macOS | `zsh Mac/install/install.sh` |
| Ubuntu | `zsh Ubuntu/install/install.sh` |
| Ubuntu on WSL | `zsh WSL/install/install.sh` (inside WSL) |
| Linux server | `bash Server/install/install.sh` — see the [server guide](./Server/README.md) for more details. |

## Development Setup

If you are going to contribute to this repository, install the development dependencies before you start working:

```console
uv sync
uv run prek install
```

Without these steps, the hooks may not run at commit or push time, or they may fail because `prek` is not available.

The pre-commit hook uses [pii-server](https://github.com/Neko-nos/pii-server) to check added staged lines for PII and credentials.

Start the detector before committing:

```console
pii_server init
```

The `pre-push` hook benchmarks Zsh startup time with [hyperfine](https://github.com/sharkdp/hyperfine) before pushing.

GitHub Actions also benchmarks Zsh startup time on pull requests by comparing the base and head revisions on the same runner, and it publishes benchmark history for pushes to `main`.

## Documents

- [macOS](./Mac/README.md)
- [Ubuntu](./Ubuntu/README.md)
- [Windows](./Windows/README.md)
- [Linux servers](./Server/README.md)
- [VSCode](./VSCode/README.md)
- [Zsh](./common/zsh/README.md)
- [Codex](./common/codex/README.md)
