#!/bin/zsh

# Stop running this script if any error occurs
set -e

script_dir="$(dirname "$0")"

# apt
chmod +x "$script_dir"/apt.sh
"$script_dir"/apt.sh "$script_dir"

# Zsh
chmod +x "$script_dir"/zsh.sh
"$script_dir"/zsh.sh "$script_dir"

# Git
printf 'Do you also want to set up git configurations? [y/N]:'
if read -q; then
    echo
    chmod +x "$script_dir"/git.sh
    "$script_dir"/git.sh "$script_dir"
else
    echo
fi

# Python
printf 'Do you also want to set up Python configurations? (We use pyenv + Poetry.) [y/N]:'
if read -q; then
    echo
    source "$script_dir"/python.sh
else
    echo
fi

echo 'All installation scripts have been executed successfully.'
echo 'For additional installation instructions, please refer to the configs/README.md file.'
