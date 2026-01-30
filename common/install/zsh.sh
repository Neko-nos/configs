#!/bin/zsh

# Stop running this script if any error occurs
set -e

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

# zplug
if command -v zplug >/dev/null 2>&1; then
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
script_dir="${${(%):-%N}:A:h}"
common_zshrc="${script_dir}/../zsh/.zshrc"
if [[ -f ~/.zshrc ]]; then
    echo 'You have already created .zshrc'
    printf 'Do you want to replace it with our .zshrc? [y/N]: '
    if read -q; then
        timestamp="$(date +%Y%m%d%H%M%S)"
        # Print a newline using echo because read -q doesn't.
        echo; mv ~/.zshrc ~/.zshrc_old_"${timestamp}"
        echo "Renamed your .zshrc to .zshrc_old_${timestamp} as a backup file."
        ln -s "${common_zshrc}" ~/.zshrc
    else
        echo
    fi
else
    ln -s "${common_zshrc}" ~/.zshrc
fi

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
unset -v OSNAME

echo 'Finished zsh configuration!'
echo 'Enjoy zsh!'
