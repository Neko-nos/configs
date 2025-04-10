#!/bin/zsh

# Stop running this script if any error occurs
set -e

function _set_up_gitconfig {
    touch ~/.gitconfig
    printf 'What is your email used for GitHub? : '
    read email
    printf 'What is your user name of GitHub? : '
    read name
    echo '[user]' >> ~/.gitconfig
    echo "    email = $email" >> ~/.gitconfig
    echo "    name = $name" >> ~/.gitconfig
    echo '[include]' >> ~/.gitconfig
    # ref: https://tomoyamkung.hatenadiary.org/entry/20090107/1231345630
    echo "    path = $(pwd | xargs dirname)/.gitconfig" >> ~/.gitconfig
}

if [[ -f ~/.gitconfig ]]; then
    echo 'You have already created .gitconfig'
    printf 'Do you want to include our .gitconfig? [y/N]: '
    if read -q; then
        timestamp="$(date +%Y%m%d%H%M%S)"
        echo; mv ~/.gitconfig ~/.gitconfig_old_"$timestamp"
        echo "Renamed your .gitconfig to .gitconfig_old_$timestamp as a backup file."
        _set_up_gitconfig
    else
        echo
    fi
else
    echo; _set_up_gitconfig
fi

echo 'Finished git configuration!'
echo ''
