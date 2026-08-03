#!/usr/bin/env zsh

# Stop running this script if any error occurs
set -e

script_dir="${${(%):-%N}:A:h}"
common_install_dir="${script_dir}/../../common/install"
common_install_dir="${common_install_dir:A}"

source "${script_dir}/utils.sh"

if command -v brew >/dev/null 2>&1; then
    __install_formula codex
    echo 'Finished Codex CLI installation!'
    echo ''
else
    echo 'Homebrew is required to install Codex CLI on Mac.'
    echo 'Skipping Codex CLI installation.'
    echo
fi

source "${common_install_dir}/codex.sh"

codex_home="${CODEX_HOME:-$HOME/.codex}"
mkdir -p "${codex_home}/skills"
__install_repo_path \
    "${common_install_dir}/../codex/skills/operate-tart-vm" \
    "${codex_home}/skills/operate-tart-vm" \
    'operate-tart-vm skill' \
    link
