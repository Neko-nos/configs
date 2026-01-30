#!/bin/zsh

# Stop running this script if any error occurs
set -e

script_dir="${${(%):-%N}:A:h}"
common_gitdir="${script_dir}/../git"

#######################################
# Set up ~/.gitconfig with user info and a shared include.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Writes configuration to ~/.gitconfig
#######################################
function __set_up_gitconfig {
    touch ~/.gitconfig
    printf 'What is your email used for GitHub? : '
    read -r email
    printf 'What is your GitHub username? : '
    read -r name
    echo '[user]' >> ~/.gitconfig
    echo "    email = ${email}" >> ~/.gitconfig
    echo "    name = ${name}" >> ~/.gitconfig
    echo '[include]' >> ~/.gitconfig
    local common_gitconfig="${common_gitdir:A}/.gitconfig"
    echo "    path = ${common_gitconfig:A}" >> ~/.gitconfig
}

if [[ -f ~/.gitconfig ]]; then
    echo 'You have already created .gitconfig'
    printf 'Do you want to include our .gitconfig? [y/N]: '
    if read -q; then
        timestamp="$(date +%Y%m%d%H%M%S)"
        # Print a newline using echo because read -q doesn't.
        echo; mv ~/.gitconfig ~/.gitconfig_old_"${timestamp}"
        echo "Renamed your .gitconfig to .gitconfig_old_${timestamp} as a backup file."
        __set_up_gitconfig
    else
        echo
    fi
else
    echo; __set_up_gitconfig
fi

if [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/git/ignore" ]]; then
    echo 'You have already created global git ignore file.'
    printf 'Do you want to replace it with our global git ignore file? [y/N]: '
    if read -q; then
        timestamp="$(date +%Y%m%d%H%M%S)"
        # Print a newline using echo because read -q doesn't.
        echo; mv "${XDG_CONFIG_HOME:-$HOME/.config}/git/ignore" "${XDG_CONFIG_HOME:-$HOME/.config}/git/ignore_old_${timestamp}"
        echo "Renamed your global git ignore file to ignore_old_${timestamp} as a backup file."
        ln -s "${common_gitdir:A}/.gitignore_template" "${XDG_CONFIG_HOME:-$HOME/.config}/git/ignore"
    else
        echo
    fi
else
    mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/git"
    ln -s "${common_gitdir:A}/.gitignore_template" "${XDG_CONFIG_HOME:-$HOME/.config}/git/ignore"
fi

echo 'Finished git configuration!'
echo ''
