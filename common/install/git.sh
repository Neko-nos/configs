#!/bin/zsh

# Stop running this script if any error occurs
set -e

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
    local script_dir="${${(%):-%N}:A:h}"
    local common_gitconfig="${script_dir}/../git/.gitconfig"
    echo "    path = ${common_gitconfig:A}" >> ~/.gitconfig
}

if [[ -f ~/.gitconfig ]]; then
    echo 'You have already created .gitconfig'
    printf 'Do you want to include our .gitconfig? [y/N]: '
    if read -q; then
        local timestamp="$(date +%Y%m%d%H%M%S)"
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

echo 'Finished git configuration!'
echo ''
