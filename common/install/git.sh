#!/bin/zsh

# Stop running this script if any error occurs
set -e

script_dir="${${(%):-%N}:A:h}"
common_gitdir="${script_dir}/../git"

source "${script_dir}/utils.sh"

#######################################
# Set up ~/.gitconfig with user info and a shared include.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Writes configuration to ~/.gitconfig
#######################################
function __set_up_gitconfig() {
    touch ~/.gitconfig
    printf 'What is your email used for GitHub? : '
    read -r email
    printf 'What is your GitHub username? : '
    read -r name
    echo '[user]' >>~/.gitconfig
    echo "    email = ${email}" >>~/.gitconfig
    echo "    name = ${name}" >>~/.gitconfig
    echo '[include]' >>~/.gitconfig
    local common_gitconfig="${common_gitdir:A}/.gitconfig"
    echo "    path = ${common_gitconfig:A}" >>~/.gitconfig
}

if [[ -f ~/.gitconfig ]]; then
    echo 'You have already created .gitconfig'
    if __confirm 'Do you want to include our .gitconfig? [y/N]: '; then
        timestamp="$(date +%Y%m%d%H%M%S)"
        mv ~/.gitconfig ~/.gitconfig_old_"${timestamp}"
        echo "Renamed your .gitconfig to .gitconfig_old_${timestamp} as a backup file."
        __set_up_gitconfig
    fi
else
    echo
    __set_up_gitconfig
fi

mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/git"
__install_repo_path "${common_gitdir}/.gitignore_template" "${XDG_CONFIG_HOME:-$HOME/.config}/git/ignore" 'global git ignore file' link

echo 'Finished git configuration!'
echo ''
