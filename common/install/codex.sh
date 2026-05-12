#!/bin/zsh

# Stop running this script if any error occurs
set -e

script_dir="${${(%):-%N}:A:h}"
common_codexdir="${script_dir}/../codex"
codex_home="${CODEX_HOME:-$HOME/.codex}"

source "${script_dir}/utils.sh"

mkdir -p "${codex_home}"

__link_if_missing "${common_codexdir}/AGENTS.md" "${codex_home}/AGENTS.md" 'AGENTS.md' "${codex_home}"
__link_if_missing "${common_codexdir}/config.toml" "${codex_home}/config.toml" 'config.toml' "${codex_home}"

echo 'Finished codex configuration!'
echo ''
