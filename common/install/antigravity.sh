#!/usr/bin/env zsh

set -euo pipefail

script_dir="${${(%):-%N}:A:h}"
common_geminidir="${script_dir}/../gemini"
common_skillsdir="${script_dir}/../skills"
gemini_home="${HOME}/.gemini"

source "${script_dir}/utils.sh"

#######################################
# Install or update Antigravity CLI.
# Globals:
#   HOME
#   TMPDIR
#   commands
# Arguments:
#   None
# Outputs:
#   Writes progress messages and prompts to stdout and stderr
# Returns:
#   0 if Antigravity CLI is installed, updated, or skipped
#######################################
function __install_or_update_antigravity() {
    local target_bin_dir="${HOME}/.local/bin"
    local agy_bin=""

    # Fall back to ~/.local/bin/agy when it is not yet on PATH (e.g. during
    # Server/install/install.sh), and resolve the executable directly to bypass
    # the interactive `agy` wrapper function in common/zsh/functions.sh.
    if ((${+commands[agy]})); then
        agy_bin="${commands[agy]}"
    elif [[ -x "${target_bin_dir}/agy" ]]; then
        agy_bin="${target_bin_dir}/agy"
    fi

    if [[ -n "${agy_bin}" ]]; then
        echo 'You have already installed Antigravity CLI.'
        if __confirm 'Do you want to update Antigravity CLI? [y/N]: '; then
            "${agy_bin}" update
        fi
        return 0
    fi

    if __confirm 'Do you want to install Antigravity CLI? [y/N]: '; then
        local installer_home
        (
            installer_home="$(mktemp -d "${TMPDIR:-/tmp}/antigravity-install.XXXXXX")"
            trap 'if [[ -d "${installer_home}" ]]; then command rm -r -- "${installer_home}"; fi' EXIT
            # Isolate HOME so the upstream installer's `agy install` step does not
            # append PATH entries to symlinked repository dotfiles such as ~/.zshrc.
            curl -fsSL https://antigravity.google/cli/install.sh |
                HOME="${installer_home}" bash -s -- --dir "${target_bin_dir}"
        )
        echo "Installed Antigravity CLI to ${target_bin_dir}/agy."
    fi
}

__install_or_update_antigravity
source "${script_dir}/hooks.sh"

mkdir -p "${gemini_home}" "${gemini_home}/config" "${gemini_home}/antigravity-cli"

__install_repo_path "${common_geminidir}/AGENTS.md" "${gemini_home}/AGENTS.md" 'AGENTS.md' link
__install_repo_path "${common_geminidir}/hooks.json" "${gemini_home}/config/hooks.json" 'hooks.json' link
# Copy a rendered file instead of symlinking so {{HOME}} placeholders are
# expanded for this machine and CLI edits to settings.json do not dirty the repo.
__install_repo_path =(sed "s|{{HOME}}|${HOME}|g" "${common_geminidir}/settings.json") "${gemini_home}/antigravity-cli/settings.json" 'settings.json' copy

if [[ "$(uname -s)" == 'Darwin' ]]; then
    mkdir -p "${gemini_home}/config/skills"
    __install_repo_path \
        "${common_skillsdir}/operate-tart-vm" \
        "${gemini_home}/config/skills/operate-tart-vm" \
        'operate-tart-vm skill' \
        link
fi

echo 'Finished Antigravity configuration!'
echo ''
