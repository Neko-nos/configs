#!/bin/bash

#######################################
# Read a yes/no confirmation from stdin.
# Arguments:
#   Prompt message.
# Outputs:
#   Writes the prompt to stdout.
# Returns:
#   0 if the user answers yes, 1 otherwise.
#######################################
function __confirm() {
    local prompt="${1}"
    local answer=""

    printf "%s" "${prompt}"
    read -r -n 1 answer
    # Print a newline because read -n doesn't.
    echo
    if [[ "${answer}" == "y" || "${answer}" == "Y" ]]; then
        return 0
    fi
    return 1
}

#######################################
# Install a symlink, backing up an existing destination after confirmation.
# Arguments:
#   Source path.
#   Destination path.
#   Display name for logs and prompts.
# Outputs:
#   Writes status messages and prompts to stdout.
# Returns:
#   0 if installed, already linked, or intentionally skipped.
#######################################
function __install_symlink() {
    local source_path="${1}"
    local destination_path="${2}"
    local display_name="${3}"
    local backup_path
    local source_resolved_path

    if [[ ! -e "${source_path}" && ! -L "${source_path}" ]]; then
        printf "Source not found for %s: %s\n" "${display_name}" "${source_path}" >&2
        return 1
    fi

    source_resolved_path="$(readlink -f "${source_path}")"

    if [[ -L "${destination_path}" && "$(readlink -f "${destination_path}")" == "${source_resolved_path}" ]]; then
        printf "You have already linked %s to the repository copy.\n" "${display_name}"
        return 0
    fi

    if [[ -e "${destination_path}" || -L "${destination_path}" ]]; then
        if ! __confirm "Do you want to replace existing ${display_name}? [y/N]: "; then
            return 0
        fi

        backup_path="${destination_path}_old_$(date +%Y%m%d%H%M%S)"
        mv "${destination_path}" "${backup_path}"
        printf "Renamed existing %s to %s as a backup.\n" "${display_name}" "${backup_path}"
    fi

    ln -s "${source_resolved_path}" "${destination_path}"
    printf "Created symlink: %s -> %s\n" "${destination_path}" "${source_resolved_path}"
}
