#!/bin/zsh

# Stop running this script if any error occurs
set -e

# zplug
if [[ -d ~/.zplug ]]; then
    echo 'You have already installed zplug.'
else
    # ref: https://github.com/zplug/zplug?tab=readme-ov-file#the-best-way
    curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh
fi

# dircolors
if [[ -f ~/.dircolors-solarized/dircolors.ansi-light ]]; then
    echo 'You have already cloned dircolors-solarized.'
else
    git clone https://github.com/seebi/dircolors-solarized.git ~/.dircolors-solarized
fi
echo

# Create a symbolic link for .zshrc
if [[ -f ~/.zshrc ]]; then
    echo 'You have already created .zshrc'
    printf 'Do you want to replace it with our .zshrc? [y/N]: '
    if read -q; then
        timestamp="$(date +%Y%m%d%H%M%S)"
        echo; mv ~/.zshrc ~/.zshrc_old_"$timestamp"
        echo "Renamed your .zshrc to .zshrc_old_$timestamp as a backup file."
        # An absolute path is preferred when creating a symbolic link
        ln -s "$(pwd)"/common/zsh/.zshrc ~/.zshrc
        source ~/.zshrc
    else
        echo
    fi
else
    echo
    ln -s "$(pwd)"/common/zsh/.zshrc ~/.zshrc
    source ~/.zshrc
fi

echo 'Finished zsh configuration!'
echo 'Enjoy zsh!'
echo ''
