#!/bin/zsh

# Stop running this script if any error occurs
set -e

script_dir="${${(%):-%N}:A:h}"
common_codexdir="${script_dir}/../codex"
codex_home="${CODEX_HOME:-$HOME/.codex}"

source "${script_dir}/utils.sh"
source "${script_dir}/rust.sh"

mkdir -p "${codex_home}"

__install_repo_path "${common_codexdir}/AGENTS.md" "${codex_home}/AGENTS.md" 'AGENTS.md' link
__install_repo_path "${common_codexdir}/config.toml" "${codex_home}/config.toml" 'config.toml' link
__install_repo_path "${common_codexdir}/hooks.json" "${codex_home}/hooks.json" 'hooks.json' link

echo 'Finished codex configuration!'
echo ''
