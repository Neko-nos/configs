#!/usr/bin/env zsh

set -euo pipefail

script_dir="${${(%):-%N}:A:h}"
common_claudedir="${script_dir}/../claude"
common_codexdir="${script_dir}/../codex"

source "${script_dir}/utils.sh"

#######################################
# Install Claude Code when the claude command is missing.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Writes progress messages to stdout and stderr
# Returns:
#   0 if Claude Code is installed, already present, or skipped
#######################################
function __install_claude_if_missing() {
    if command -v claude >/dev/null 2>&1; then
        echo 'You have already installed Claude Code.'
        return 0
    fi

    if __confirm 'Do you want to install Claude Code? [y/N]: '; then
        curl -fsSL https://claude.ai/install.sh | bash
    fi
}

__install_claude_if_missing

mkdir -p "${CLAUDE_CONFIG_DIR:-${HOME}/.claude}"

__install_repo_path "${common_claudedir}/settings.json" "${CLAUDE_CONFIG_DIR:-${HOME}/.claude}/settings.json" 'settings.json' link
__install_repo_path "${common_codexdir}/AGENTS.md" "${CLAUDE_CONFIG_DIR:-${HOME}/.claude}/CLAUDE.md" 'CLAUDE.md' link

echo 'Finished Claude Code configuration!'
echo ''
