#!/usr/bin/env zsh

# Stop running this script if any error occurs
set -e

script_dir="$(dirname "$0")"

# Homebrew
chmod +x "$script_dir"/brew.sh
"$script_dir"/brew.sh "$script_dir"

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
printf 'Do you also want to set up Python configurations? [y/N]:'
if read -q; then
    echo
    chmod +x "$script_dir"/python.sh
    source "$script_dir"/python.sh
else
    echo
fi

echo 'All installation scripts have been executed successfully.'
echo 'For additional installation instructions, please refer to the configs/README.md file.'
