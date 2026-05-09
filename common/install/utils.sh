#!/bin/zsh

#######################################
# Read a yes/no confirmation from stdin.
# Globals:
#   None
# Arguments:
#   1: Prompt message
# Outputs:
#   Writes the prompt and a trailing newline to stdout.
# Returns:
#   0 if the user answers yes, 1 otherwise.
#######################################
function __confirm() {
    local prompt="${1}"

    printf '%s' "${prompt}"
    if read -q; then
        # Print a newline using echo because read -q doesn't.
        echo
        return 0
    fi

    echo
    return 1
}

#######################################
# Create a symbolic link when target is missing.
# Globals:
#   None
# Arguments:
#   Source file path
#   Destination file path
#   Display name for logs
#   Configuration home directory for logs
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
    local config_home="${4}"

    if [[ ! -f "${source_path}" ]]; then
        echo "Source file not found: ${source_path}"
        return 1
    fi

    if [[ -e "${destination_path}" || -L "${destination_path}" ]]; then
        echo "You have already created ${display_name} in ${config_home}."
        return 0
    fi

    ln -s "${source_path:A}" "${destination_path}"
    echo "Created symlink: ${destination_path} -> ${source_path:A}"
}
