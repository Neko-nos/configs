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
# Select the interactive shell for this server.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Writes "bash" for Slurm-managed servers or "zsh" otherwise.
# Returns:
#   0 on success.
#######################################
function __select_server_shell() {
    local slurm_command

    for slurm_command in sbatch scontrol sinfo squeue srun; do
        if command -v "${slurm_command}" >/dev/null 2>&1; then
            printf "bash\n"
            return 0
        fi
    done

    printf "zsh\n"
}

#######################################
# Install a repository-managed file with an optional replacement prompt.
# Arguments:
#   Source path.
#   Destination path.
#   Display name for logs and prompts.
#   Install mode: link or copy.
# Outputs:
#   Writes status messages and prompts to stdout.
# Returns:
#   0 if installed, already matching, or intentionally skipped.
#   1 if the source does not exist or the install mode is invalid.
#######################################
function __install_repo_path() {
    local source_path="${1}"
    local destination_path="${2}"
    local display_name="${3}"
    local install_mode="${4}"
    local backup_path
    local source_resolved_path

    if [[ "${install_mode}" != "link" && "${install_mode}" != "copy" ]]; then
        printf "Invalid install mode for %s: %s\n" "${display_name}" "${install_mode}" >&2
        return 1
    fi

    if [[ ! -e "${source_path}" && ! -L "${source_path}" ]]; then
        printf "Source not found for %s: %s\n" "${display_name}" "${source_path}" >&2
        return 1
    fi

    source_resolved_path="$(readlink -f "${source_path}")"

    if [[ "${install_mode}" == "link" && -L "${destination_path}" \
        && "$(readlink -f "${destination_path}")" == "${source_resolved_path}" ]]; then
        printf "You have already linked %s to the repository copy.\n" "${display_name}"
        return 0
    fi

    if [[ "${install_mode}" == "copy" && -f "${destination_path}" && ! -L "${destination_path}" ]] \
        && cmp -s "${source_path}" "${destination_path}"; then
        printf "You have already copied %s from the repository.\n" "${display_name}"
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

    if [[ "${install_mode}" == "link" ]]; then
        ln -s "${source_resolved_path}" "${destination_path}"
        printf "Created symlink: %s -> %s\n" "${destination_path}" "${source_resolved_path}"
    else
        cp "${source_path}" "${destination_path}"
        printf "Copied %s to %s\n" "${source_path}" "${destination_path}"
    fi
}
