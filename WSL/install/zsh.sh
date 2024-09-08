#!/bin/zsh

# Stop running this script if any error occurs
set -e

# Peco
# Installing peco via apt on Ubuntu 24.04 LTS can result in garbled output
# ref: https://zenn.dev/mato/scraps/2b0c423ad9da2c
if [[ -x "$(where peco)" ]]; then
    echo 'You have already installed peco'
else
    ubuntu_version="$(lsb_release -a | grep Release | sed 's/Release:\s\+//g')"
    if [[ "$ubuntu_version" -eq 24.04 ]]; then
        wget https://github.com/peco/peco/releases/download/v0.5.11/peco_linux_amd64.tar.gz
        tar -xzf peco_linux_amd64.tar.gz
        sudo mv peco_linux_amd64/peco /usr/local/bin/
    else
        sudo apt update
        sudo apt upgrade -y
        sudo apt install peco
    fi
fi

# zplug
if [[ -d ~/.zplug ]]; then
    echo 'You have already installed zplug.'
else
    # ref: https://github.com/zplug/zplug?tab=readme-ov-file#the-best-way
    curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh
fi
# Create a symbolic link for .zshrc
if [[ -f ~/.zshrc ]]; then
    echo 'You have already created .zshrc'
    printf 'Do you want to replace it with our .zshrc? [y/N]: '
    if read -q; then
        timestamp="$(date +%Y%m%d%H%M%S)"
        echo; mv .zshrc .zshrc_old_"$timestamp"
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
