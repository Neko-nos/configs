#!/bin/zsh

# Stop running this script if any error occurs
set -e

script_dir="${${(%):-%N}:A:h}"
common_codexdir="${script_dir}/../codex"
codex_home="${CODEX_HOME:-$HOME/.codex}"

source "${script_dir}/utils.sh"
source "${script_dir}/rust.sh"

mkdir -p "${codex_home}" "${codex_home}/rules"

__install_repo_path "${common_codexdir}/AGENTS.md" "${codex_home}/AGENTS.md" 'AGENTS.md' link
__install_repo_path "${common_codexdir}/config.toml" "${codex_home}/config.toml" 'config.toml' link
__install_repo_path "${common_codexdir}/hooks.json" "${codex_home}/hooks.json" 'hooks.json' link

# Rules
# Codex ignores symlinked rule files because its rule discovery accepts only regular files.
__install_repo_path "${common_codexdir}/rules/git-index.rules" "${codex_home}/rules/git-index.rules" 'Git index rules' copy
__install_repo_path "${common_codexdir}/rules/tart-vm.rules" "${codex_home}/rules/tart-vm.rules" 'Tart VM rules' copy
__install_repo_path =(sed "s|{{HOME}}|${HOME}|g" "${common_codexdir}/rules/openai-docs.rules") "${codex_home}/rules/openai-docs.rules" 'OpenAI documentation rules' copy
__install_repo_path "${common_codexdir}/rules/lua-formatting.rules" "${codex_home}/rules/lua-formatting.rules" 'Lua formatting rules' copy
__install_repo_path "${common_codexdir}/rules/nvidia-smi.rules" "${codex_home}/rules/nvidia-smi.rules" 'NVIDIA SMI rules' copy
__install_repo_path "${common_codexdir}/rules/uv.rules" "${codex_home}/rules/uv.rules" 'uv rules' copy

# Prevent Codex's diagnostic database from causing excessive SSD writes.
# ref: https://github.com/openai/codex/issues/28224
# ref: https://gist.github.com/jun76/bf5f8fdde0e3866f537fc9422c65326d#disable-diagnostic-logging
if __confirm 'Have you already disabled Codex diagnostic database logging? [y/N]: '; then
    echo 'Skipped disabling Codex diagnostic database logging.'
else
    python3 "${common_codexdir}/disable_sqlite_logging.py" "${codex_home}/logs_2.sqlite"
fi

echo 'Finished codex configuration!'
echo ''
