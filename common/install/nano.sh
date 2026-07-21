#!/bin/zsh

# Stop running this script if any error occurs
set -e

script_dir="${${(%):-%N}:A:h}"
nanorc_repo_dir="${HOME}/nanorc"
nano_repo_url="https://github.com/Neko-nos/nanorc.git"
nano_syntax_dir="${HOME}/.config/nano/syntax"
user_bin_dir="${HOME}/.local/bin"

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
function __ensure_nanorc_repository {
    if [[ -d "${nanorc_repo_dir}" ]]; then
        return 0
    fi

    echo "Custom nanorc repository was not found: ${nanorc_repo_dir}"
    printf "Do you want to clone our nanorc (${nano_repo_url}) into ${nanorc_repo_dir}? [y/N]: "
    if read -q; then
        # Print a newline using echo because read -q doesn't.
        echo
        git clone "${nano_repo_url}" "${nanorc_repo_dir}"
        return 0
    fi

    echo
    echo 'Skipped nano configuration because the custom nanorc repository is unavailable.'
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
function __link_system_nano_syntax_files {
    local source_dir
    local source_file
    local -a syntax_dirs=(
        /opt/homebrew/share/nano
        /usr/local/share/nano
        /usr/share/nano
    )

    for source_dir in "${syntax_dirs[@]}"; do
        if [[ -d "${source_dir}" ]]; then
            for source_file in "${source_dir}"/*.nanorc(N); do
                __install_repo_path "${source_file}" "${nano_syntax_dir}/${source_file:t}" "system nano ${source_file:t}" link
            done
            return 0
        fi
    done

    echo 'No nano syntax directory found.'
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
function __link_custom_nano_syntax_files {
    local source_file
    local custom_syntax_dir="${nanorc_repo_dir}/syntax"

    if [[ ! -d "${custom_syntax_dir}" ]]; then
        echo "Custom nano syntax directory was not found: ${custom_syntax_dir}"
        return 1
    fi

    for source_file in "${custom_syntax_dir}"/*.nanorc(N); do
        __install_repo_path "${source_file}" "${nano_syntax_dir}/${source_file:t}" "custom ${source_file:t}" link
    done

    return 0
}

mkdir -p "${user_bin_dir}"
__install_repo_path "${script_dir}/../bin/clipboard-copy" "${user_bin_dir}/clipboard-copy" 'clipboard-copy' link
mkdir -p "${nano_syntax_dir}"
__link_system_nano_syntax_files

if __ensure_nanorc_repository; then
    __install_repo_path "${nanorc_repo_dir}/.nanorc" "${HOME}/.nanorc" '.nanorc' link
    __link_custom_nano_syntax_files
fi


unset -v script_dir
unset -v nanorc_repo_dir
unset -v nano_repo_url
unset -v nano_syntax_dir
unset -v user_bin_dir
unset -f __ensure_nanorc_repository
unset -f __link_system_nano_syntax_files
unset -f __link_custom_nano_syntax_files

echo 'Finished nano configuration!'
