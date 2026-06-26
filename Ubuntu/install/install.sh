#!/bin/zsh

# Stop running this script if any error occurs
set -e

# Keep this distinct from script_dir; sourced child installers may unset script_dir.
install_script_dir="${${(%):-%N}:A:h}"
common_install_dir="${install_script_dir}/../../common/install"
common_install_dir="${common_install_dir:A}"

# apt
source "${install_script_dir}/apt.sh"

# Zsh
source "${common_install_dir}/zsh.sh" Ubuntu

# Git
printf 'Do you also want to set up git configurations? [y/N]:'
if read -q; then
    # Print a newline using echo because read -q doesn't.
    echo
    source "${common_install_dir}/git.sh"
else
    echo
fi

# GitHub CLI
printf 'Do you also want to install GitHub CLI? [y/N]:'
if read -q; then
    # Print a newline using echo because read -q doesn't.
    echo
    source "${install_script_dir}/gh.sh"
else
    echo
fi

# GitHub SSH
printf 'Do you also want to set up GitHub SSH authentication? [y/N]:'
if read -q; then
    # Print a newline using echo because read -q doesn't.
    echo
    source "${common_install_dir}/github_ssh.sh"
else
    echo
fi

# VSCode
printf 'Do you also want to set up VSCode configurations? [y/N]:'
if read -q; then
    # Print a newline using echo because read -q doesn't.
    echo
    source "${install_script_dir}/vscode.sh"
else
    echo
fi

# Nano
printf 'Do you also want to set up nano configurations? [y/N]:'
if read -q; then
    # Print a newline using echo because read -q doesn't.
    echo
    source "${common_install_dir}/nano.sh"
else
    echo
fi

# Docker
printf 'Do you also want to set up Docker and NVIDIA Container Toolkit? [y/N]:'
if read -q; then
    # Print a newline using echo because read -q doesn't.
    echo
    source "${common_install_dir}/docker.sh"
else
    echo
fi

# Codex
printf 'Do you also want to set up Codex CLI and configurations? [y/N]:'
if read -q; then
    # Print a newline using echo because read -q doesn't.
    echo
    source "${install_script_dir}/codex.sh"
else
    echo
fi

# Claude Code
printf 'Do you also want to set up Claude Code configurations? [y/N]:'
if read -q; then
    # Print a newline using echo because read -q doesn't.
    echo
    source "${common_install_dir}/claude.sh"
else
    echo
fi

# Python
printf 'Do you also want to set up Python configurations? [y/N]:'
if read -q; then
    # Print a newline using echo because read -q doesn't.
    echo
    source "${common_install_dir}/python.sh"
else
    echo
fi

# markdownlint
printf 'Do you also want to install markdownlint-cli2? [y/N]:'
if read -q; then
    # Print a newline using echo because read -q doesn't.
    echo
    source "${install_script_dir}/markdownlint.sh"
else
    echo
fi

# actionlint
printf 'Do you also want to install actionlint? [y/N]:'
if read -q; then
    # Print a newline using echo because read -q doesn't.
    echo
    source "${install_script_dir}/actionlint.sh"
else
    echo
fi

echo 'All installation scripts have been executed successfully.'
echo 'For additional installation instructions, please refer to the configs/README.md file.'
