#!/usr/bin/env zsh

# Stop running this script if any error occurs
set -e

# zplug
if [[ -d ~/.zplug ]]; then
    echo 'You have already installed zplug.'
else
    # ref: https://github.com/zplug/zplug?tab=readme-ov-file#the-best-way
    curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh
fi
# We create the minimum symbolic link to source our zshrc
if [[ -f ~/.zshrc ]]; then
    echo 'You have already created .zshrc'
    printf 'Do you want to replace it with our .zshrc? [y/N]: '
    if read -q; then
        timestamp="$(date +%Y%m%d%H%M%S)"
        echo; mv ~/.zshrc ~/.zshrc_old_"$timestamp"
        echo "Renamed your .zshrc to .zshrc_old_$timestamp as a backup file."
        # ${1} is the relatice path of the directory of this script
        cd ${1}
        cd ..
        # An absolute path is preferred when creating a symbolic link
        ln -s "$(pwd)"/.zshrc ~/.zshrc
        source ~/.zshrc
    else
        echo
    fi
else
    echo
    # ${1} is the relatice path of the directory of this script
    cd ${1}
    cd ..
    ln -s "$(pwd)"/.zshrc ~/.zshrc
    source ~/.zshrc
fi

echo 'Finished zsh configuration!'
echo 'Enjoy zsh!'
echo ''
