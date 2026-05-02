#!/bin/zsh

# Stop running this script if any error occurs
set -e

script_dir="${${(%):-%N}:A:h}"
common_claudedir="${script_dir}/../claude"
common_codexdir="${script_dir}/../codex"
claude_home="${CLAUDE_HOME:-$HOME/.claude}"

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
function __install_claude_if_missing {
    if command -v claude >/dev/null 2>&1; then
        echo 'You have already installed Claude Code.'
        return 0
    fi

    printf 'Do you want to install Claude Code? [y/N]: '
    if read -q; then
        # Print a newline using echo because read -q doesn't.
        echo
        curl -fsSL https://claude.ai/install.sh | bash
    else
        echo
    fi
}

__install_claude_if_missing

mkdir -p "${claude_home}"

__link_if_missing "${common_claudedir}/settings.json" "${claude_home}/settings.json" 'settings.json' "${claude_home}"
__link_if_missing "${common_codexdir}/agents.md" "${claude_home}/CLAUDE.md" 'CLAUDE.md' "${claude_home}"

echo 'Finished Claude Code configuration!'
echo ''
