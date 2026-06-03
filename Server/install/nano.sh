#!/bin/bash

set -euo pipefail

script_dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
nanorc_repo_dir="${HOME}/nanorc"
nano_repo_url="https://github.com/Neko-nos/nanorc.git"
nano_syntax_dir="${HOME}/.config/nano/syntax"

# shellcheck source=/dev/null
source "${script_dir}/utils.sh"

#######################################
# Clone the custom nano configuration repository when it is missing.
# Arguments:
#   None
# Outputs:
#   Writes prompts and status messages to stdout
# Returns:
#   0 if the repository exists or was cloned, 1 if setup should be skipped
#######################################
function __ensure_nanorc_repository() {
    if [[ -d "${nanorc_repo_dir}" ]]; then
        return 0
    fi

    echo "Custom nanorc repository was not found: ${nanorc_repo_dir}"
    if __confirm "Do you want to clone our nanorc (${nano_repo_url}) into ${nanorc_repo_dir}? [y/N]: "; then
        git clone "${nano_repo_url}" "${nanorc_repo_dir}"
        return 0
    fi

    echo "Skipped nano configuration because the custom nanorc repository is unavailable."
    return 1
}

#######################################
# Link nano syntax files from the system installation.
# Arguments:
#   None
# Outputs:
#   Writes status messages to stdout
# Returns:
#   0 on success or when no system syntax directory is available
#######################################
function __link_system_nano_syntax_files() {
    local source_dir
    local source_file

    for source_dir in /usr/share/nano /usr/local/share/nano; do
        if [[ -d "${source_dir}" ]]; then
            for source_file in "${source_dir}"/*.nanorc; do
                [[ -e "${source_file}" ]] || continue
                __install_symlink "${source_file}" "${nano_syntax_dir}/${source_file##*/}" "system nano ${source_file##*/}"
            done
            return 0
        fi
    done

    echo "No nano syntax directory found."
    return 0
}

#######################################
# Link custom nano syntax files from the custom repository.
# Arguments:
#   None
# Outputs:
#   Writes status messages to stdout
# Returns:
#   0 on success
#######################################
function __link_custom_nano_syntax_files() {
    local custom_syntax_dir="${nanorc_repo_dir}/syntax"
    local source_file

    if [[ ! -d "${custom_syntax_dir}" ]]; then
        echo "Custom nano syntax directory was not found: ${custom_syntax_dir}"
        return 1
    fi

    for source_file in "${custom_syntax_dir}"/*.nanorc; do
        [[ -e "${source_file}" ]] || continue
        __install_symlink "${source_file}" "${nano_syntax_dir}/${source_file##*/}" "custom ${source_file##*/}"
    done

    return 0
}

mkdir -p "${nano_syntax_dir}"
__link_system_nano_syntax_files

if __ensure_nanorc_repository; then
    __install_symlink "${nanorc_repo_dir}/.nanorc" "${HOME}/.nanorc" ".nanorc"
    __link_custom_nano_syntax_files
fi

echo "Finished nano configuration!"
