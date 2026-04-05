#!/bin/zsh

# Stop running this script if any error occurs
set -e

#######################################
# Link a home dotfile to a repository-managed file with an optional prompt.
# Arguments:
#   1: Source file path in the repository
#   2: Destination path in the home directory
#   3: Human-readable label for prompts and status messages
# Outputs:
#   Writes status messages and prompts to stdout
# Returns:
#   0 on success, non-zero on failure
#######################################
function link_repo_dotfile() {
    local source_file="${1}"
    local destination_file="${2}"
    local display_name="${3}"
    local timestamp
    local backup_file

    if [[ ! -f "${source_file}" ]]; then
        echo "No repository-managed ${display_name} found at ${source_file}. Skipping."
        return 0
    fi

    if [[ -L "${destination_file}" && "${destination_file:A}" == "${source_file:A}" ]]; then
        echo "You have already linked ${display_name} to the repository copy."
        return 0
    fi

    if [[ -e "${destination_file}" || -L "${destination_file}" ]]; then
        echo "You have already created ${display_name}"
        printf "Do you want to replace it with our ${display_name}? [y/N]: "
        if read -q; then
            timestamp="$(date +%Y%m%d%H%M%S)"
            backup_file="${destination_file}_old_${timestamp}"
            # Print a newline using echo because read -q doesn't.
            echo
            mv "${destination_file}" "${backup_file}"
            echo "Renamed your ${display_name} to ${backup_file} as a backup file."
            ln -s "${source_file:A}" "${destination_file}"
        else
            echo
        fi
        return 0
    fi

    ln -s "${source_file:A}" "${destination_file}"
}

#######################################
# Copy a repository-managed home dotfile with an optional prompt.
# Arguments:
#   1: Source file path in the repository
#   2: Destination path in the home directory
#   3: Human-readable label for prompts and status messages
# Outputs:
#   Writes status messages and prompts to stdout
# Returns:
#   0 if the destination already matches or was copied, 1 if skipped
#######################################
function copy_repo_dotfile() {
    local source_file="${1}"
    local destination_file="${2}"
    local display_name="${3}"
    local timestamp
    local backup_file

    if [[ ! -f "${source_file}" ]]; then
        echo "No repository-managed ${display_name} template found at ${source_file}. Skipping."
        return 1
    fi

    if [[ -f "${destination_file}" ]] && cmp -s "${source_file}" "${destination_file}"; then
        echo "You have already created ${display_name} from the repository template."
        return 0
    fi

    if [[ -e "${destination_file}" || -L "${destination_file}" ]]; then
        echo "You have already created ${display_name}"
        printf "Do you want to replace it with our ${display_name} template? [y/N]: "
        if read -q; then
            timestamp="$(date +%Y%m%d%H%M%S)"
            backup_file="${destination_file}_old_${timestamp}"
            # Print a newline using echo because read -q doesn't.
            echo
            mv "${destination_file}" "${backup_file}"
            echo "Renamed your ${display_name} to ${backup_file} as a backup file."
            cp "${source_file}" "${destination_file}"
            return 0
        fi

        echo
        return 1
    fi

    cp "${source_file}" "${destination_file}"
}

#######################################
# Append env vars required by .zshrc when they are not already set.
# Arguments:
#   1: OS name used to build the OS-specific config path
# Outputs:
#   Writes prompts to stdout and appends settings to ~/.zprofile
# Returns:
#   0 on success
#######################################
function ensure_zprofile_envs() {
    local os_name="${1}"

    # Our .zshrc requires some env variables to be set in advance
    printf 'Did you already set FILTER_CMD in .zprofile? [y/N]: '
    if ! read -q; then
        # Print a newline using echo because read -q doesn't.
        echo
        echo 'Appending FILTER_CMD to ~/.zprofile.'
        echo '# Envs used for .zshrc' >> ~/.zprofile
        echo 'export FILTER_CMD="fzf"' >> ~/.zprofile
    fi
    echo

    printf 'Did you already set envs for CONFIGS_COMMON_ZSH and __os_specific_zsh_var in .zprofile? [y/N]: '
    if ! read -q; then
        echo
        echo 'Appending CONFIGS_COMMON_ZSH and __os_specific_zsh_var to ~/.zprofile.'
        echo 'export CONFIGS_COMMON_ZSH="$HOME/configs/common/zsh"' >> ~/.zprofile
        echo 'export __os_specific_zsh_var="CONFIGS_${OSTYPE//[^a-zA-Z0-9]/_}_ZSH"' >> ~/.zprofile
        echo "export \${__os_specific_zsh_var}=\"\$HOME/configs/${os_name}\"" >> ~/.zprofile
        echo 'unset -v __os_specific_zsh_var' >> ~/.zprofile
    fi
    echo
}

#######################################
# Configure ~/.zprofile from a template or by appending required env vars.
# Arguments:
#   1: OS name used to resolve the template path
#   2: Installer script directory
# Outputs:
#   Writes prompts to stdout and updates ~/.zprofile
# Returns:
#   0 on success
#######################################
function configure_zprofile() {
    local os_name="${1}"
    local installer_dir="${2}"
    local zprofile_template="${installer_dir}/../../${os_name}/.zprofile_template"

    if [[ -f "${zprofile_template}" ]]; then
        printf 'Do you want to create ~/.zprofile from our template? [y/N]: '
        if read -q; then
            echo
            if copy_repo_dotfile "${zprofile_template}" ~/.zprofile '.zprofile'; then
                return 0
            fi
            ensure_zprofile_envs "${os_name}"
        else
            echo
            ensure_zprofile_envs "${os_name}"
        fi
    fi
}

OSNAME="${1}"
if [[ "${(L)OSNAME}" == 'mac' ]]; then
    OSNAME='Mac'
elif [[ "${(L)OSNAME}" == 'ubuntu' ]]; then
    OSNAME='Ubuntu'
elif [[ "${(L)OSNAME}" == 'wsl' ]]; then
    OSNAME='WSL'
else
    echo 'Please specify the OS name as the first argument: mac, ubuntu, or wsl.'
    exit 1
fi

__os_specific_zsh_var="CONFIGS_${OSTYPE//[^a-zA-Z0-9]/_}_ZSH"

# sheldon
if command -v sheldon >/dev/null 2>&1; then
    echo 'You have already installed sheldon.'
else
    # ref: https://github.com/rossmacarthur/sheldon?tab=readme-ov-file#pre-built-binaries
    curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh \
    | bash -s -- --repo rossmacarthur/sheldon --to ~/.local/bin
fi
if [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/sheldon/plugins.toml" ]]; then
    echo 'You have already created sheldon config file.'
else
    # Use a symlink instead of a direct path because XDG_CONFIG_HOME is shared by tools like git.
    mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/sheldon"
    script_dir="${${(%):-%N}:A:h}"
    common_sheldon_plugins="${script_dir}/../zsh/sheldon/plugins.toml"
    ln -s "${common_sheldon_plugins:A}" "${XDG_CONFIG_HOME:-$HOME/.config}/sheldon/plugins.toml"
fi

# dircolors
if [[ -f ~/.dircolors-solarized/dircolors.ansi-light ]]; then
    echo 'You have already cloned dircolors-solarized.'
else
    git clone https://github.com/seebi/dircolors-solarized.git ~/.dircolors-solarized
fi
echo

script_dir="${${(%):-%N}:A:h}"
common_zshrc="${script_dir}/../zsh/.zshrc"
os_specific_p10k="${script_dir}/../../${OSNAME}/.p10k.zsh"
link_repo_dotfile "${common_zshrc}" ~/.zshrc '.zshrc'
link_repo_dotfile "${os_specific_p10k}" ~/.p10k.zsh '.p10k.zsh'
configure_zprofile "${OSNAME}" "${script_dir}"

# Only source ~/.zprofile here. ~/.zshrc depends on tools and plugins that may
# still be unavailable during installation, so loading it in the installer can
# fail before the new shell environment is fully ready.
source ~/.zprofile

# Cleaning up
unset -v script_dir
unset -v common_zshrc
unset -v os_specific_p10k
unset -v OSNAME
unset -f link_repo_dotfile
unset -f copy_repo_dotfile
unset -f ensure_zprofile_envs
unset -f configure_zprofile

echo 'Finished zsh configuration!'
echo 'Please restart your shell to load ~/.zshrc and the installed plugins.'
echo 'Enjoy zsh!'
