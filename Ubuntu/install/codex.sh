#!/bin/zsh

# Stop running this script if any error occurs
set -e

script_dir="${${(%):-%N}:A:h}"
common_install_dir="${script_dir}/../../common/install"
common_install_dir="${common_install_dir:A}"

source "${script_dir}/utils.sh"

__install_package npm
__install_package bubblewrap

if command -v npm >/dev/null 2>&1; then
    if command -v codex >/dev/null 2>&1; then
        echo 'You have already installed Codex CLI.'
        if __confirm 'Update Codex CLI? [y/N]: '; then
            npm install -g @openai/codex
        fi
    else
        if __confirm 'Install Codex CLI? [y/N]: '; then
            npm install -g @openai/codex
        fi
    fi

    echo 'Finished Codex CLI installation!'
    echo ''
else
    echo 'npm is required to install Codex CLI.'
    echo 'Skipping Codex CLI installation.'
    echo
fi

source "${common_install_dir}/codex.sh"
