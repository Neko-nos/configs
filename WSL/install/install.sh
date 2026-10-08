#!/usr/bin/env zsh

set -euo pipefail

# Keep this distinct from script_dir; sourced child installers may unset script_dir.
install_script_dir="${${(%):-%N}:A:h}"
common_install_dir="${install_script_dir}/../../common/install"
common_install_dir="${common_install_dir:A}"

# apt
source "${install_script_dir}/apt.sh"

# Zsh
source "${common_install_dir}/zsh.sh" WSL

# Terminal multiplexers
source "${common_install_dir}/mux.sh"

# Git
if __confirm 'Do you also want to set up git configurations? [y/N]: '; then
    source "${common_install_dir}/git.sh"
fi

# GitHub CLI
if __confirm 'Do you also want to install GitHub CLI? [y/N]: '; then
    source "${install_script_dir}/gh.sh"
fi

# GitHub SSH
if __confirm 'Do you also want to set up GitHub SSH authentication? [y/N]: '; then
    source "${common_install_dir}/github_ssh.sh"
fi

# VSCode
if __confirm 'Do you also want to install and configure VSCode? [y/N]: '; then
    source "${install_script_dir}/vscode.sh"
fi

# Nano
if __confirm 'Do you also want to set up nano configurations? [y/N]: '; then
    source "${common_install_dir}/nano.sh"
fi

# Docker
if __confirm 'Do you also want to set up Docker and NVIDIA Container Toolkit? [y/N]: '; then
    source "${common_install_dir}/docker.sh"
fi

# WSL
if __confirm 'Do you also want to set up WSL system configuration? [y/N]: '; then
    source "${install_script_dir}/wsl.sh"
fi

# Codex
if __confirm 'Do you also want to set up Codex CLI and configurations? [y/N]: '; then
    source "${install_script_dir}/codex.sh"
fi

# Claude Code
if __confirm 'Do you also want to set up Claude Code configurations? [y/N]: '; then
    source "${common_install_dir}/claude.sh"
fi

# Python
if __confirm 'Do you also want to set up Python configurations? [y/N]: '; then
    source "${common_install_dir}/python.sh"
fi

# markdownlint
if __confirm 'Do you also want to install markdownlint-cli2? [y/N]: '; then
    source "${install_script_dir}/markdownlint.sh"
fi

# actionlint
if __confirm 'Do you also want to install actionlint? [y/N]: '; then
    source "${install_script_dir}/actionlint.sh"
fi

if __confirm 'Do you also want to install common command-line tools? [y/N]: '; then
    bash "${common_install_dir}/commands.sh"
fi

echo 'All installation scripts have been executed successfully.'
echo 'For additional installation instructions, please refer to the configs/README.md file.'
