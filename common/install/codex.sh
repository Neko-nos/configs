#!/bin/zsh

# Stop running this script if any error occurs
set -e

script_dir="${${(%):-%N}:A:h}"
common_codexdir="${script_dir}/../codex"
codex_home="${CODEX_HOME:-$HOME/.codex}"

#######################################
# Create a symbolic link when target is missing.
# Globals:
#   None
# Arguments:
#   Source file path
#   Destination file path
#   Display name for logs
# Outputs:
#   Writes progress messages to stdout
# Returns:
#   0 if target already exists or symlink creation succeeds
#   1 if source file does not exist
#######################################
function __link_if_missing {
    local source_path="${1}"
    local destination_path="${2}"
    local display_name="${3}"

    if [[ ! -f "${source_path}" ]]; then
        echo "Source file not found: ${source_path}"
        return 1
    fi

    if [[ -e "${destination_path}" || -L "${destination_path}" ]]; then
        echo "You have already created ${display_name} in ${codex_home}."
        return 0
    fi

    ln -s "${source_path:A}" "${destination_path}"
    echo "Created symlink: ${destination_path} -> ${source_path:A}"
}

mkdir -p "${codex_home}"

__link_if_missing "${common_codexdir}/agents.md" "${codex_home}/agents.md" 'agents.md'
__link_if_missing "${common_codexdir}/config.toml" "${codex_home}/config.toml" 'config.toml'

echo 'Finished codex configuration!'
echo ''
