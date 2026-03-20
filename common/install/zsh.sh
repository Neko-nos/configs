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

# Our .zshrc requires some env variables to be set in advance
printf 'Did you already set FILTER_CMD in .zprofile? [y/N]: '
if ! read -q; then
    # Print a newline using echo because read -q doesn't.
    echo
    echo '# Envs used for .zshrc' >> ~/.zprofile
    echo 'export FILTER_CMD="fzf"' >> ~/.zprofile
fi

printf 'Did you already set envs for CONFIGS_COMMON_ZSH and __os_specific_zsh_var in .zprofile? [y/N]: '
if ! read -q; then
    echo
    echo 'export CONFIGS_COMMON_ZSH="$HOME/configs/common/zsh"' >> ~/.zprofile
    echo 'export __os_specific_zsh_var="CONFIGS_${OSTYPE//[^a-zA-Z0-9]/_}_ZSH"' >> ~/.zprofile
    echo "export \${__os_specific_zsh_var}=\"\$HOME/configs/${OSNAME}\"" >> ~/.zprofile
    echo 'unset -v __os_specific_zsh_var' >> ~/.zprofile
fi

source ~/.zprofile
source ~/.zshrc

# Cleaning up
unset -v script_dir
unset -v common_zshrc
unset -v os_specific_p10k
unset -v OSNAME
unset -f link_repo_dotfile

echo 'Finished zsh configuration!'
echo 'Enjoy zsh!'
