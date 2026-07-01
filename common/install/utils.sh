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
# Install a repository-managed path with an optional replacement prompt.
# Globals:
#   None
# Arguments:
#   Source path; copy mode supports files, link mode supports files and directories
#   Destination path; copy mode supports files, link mode supports files and directories
#   Display name for logs and prompts
#   Install mode: link or copy
# Outputs:
#   Writes status messages and prompts to stdout
# Returns:
#   0 if installed, already matching, or intentionally skipped
#   1 if source path does not exist or install mode is invalid
#######################################
function __install_repo_path {
    local source_path="${1}"
    local destination_path="${2}"
    local display_name="${3}"
    local install_mode="${4}"

    if [[ "${install_mode}" != 'link' && "${install_mode}" != 'copy' ]]; then
        echo "Invalid install mode for ${display_name}: ${install_mode}"
        return 1
    fi

    if [[ ! -e "${source_path}" && ! -L "${source_path}" ]]; then
        echo "Source not found for ${display_name}: ${source_path}"
        return 1
    fi

    if [[ "${install_mode}" == 'link' && -L "${destination_path}" && "${destination_path:A}" == "${source_path:A}" ]]; then
        echo "You have already linked ${display_name} to the repository copy."
        return 0
    fi

    if [[ "${install_mode}" == 'copy' && -f "${destination_path}" && ! -L "${destination_path}" ]] && cmp -s "${source_path}" "${destination_path}"; then
        echo "You have already created ${display_name} from the repository template."
        return 0
    fi

    if [[ -e "${destination_path}" || -L "${destination_path}" ]]; then
        echo "You have already created ${display_name}."
        printf "Do you want to replace it with our ${display_name}? [y/N]: "
        if read -q; then
            local timestamp="$(date +%Y%m%d%H%M%S)"
            local backup_path="${destination_path}_old_${timestamp}"
            # Print a newline using echo because read -q doesn't.
            echo
            mv "${destination_path}" "${backup_path}"
            echo "Renamed your ${display_name} to ${backup_path} as a backup."
            if [[ "${install_mode}" == 'link' ]]; then
                ln -s "${source_path:A}" "${destination_path}"
            else
                cp "${source_path}" "${destination_path}"
            fi
        else
            echo
            return 0
        fi
        return 0
    fi

    if [[ "${install_mode}" == 'link' ]]; then
        ln -s "${source_path:A}" "${destination_path}"
        echo "Created symlink: ${destination_path} -> ${source_path:A}"
    else
        cp "${source_path}" "${destination_path}"
        echo "Copied ${source_path} to ${destination_path}"
    fi
}
