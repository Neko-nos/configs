#!/usr/bin/env zsh

# Stop running this script if any error occurs
set -e

script_dir="$(dirname "$0")"

# Homebrew
source brew.sh

# Zsh
chmod +x "$script_dir"/zsh.sh
"$script_dir"/zsh.sh "$script_dir"

# Python
printf 'Do you also want to set up Python configurations? (We use pyenv + Poetry.) [y/N]:'
if read -q; then
    echo
    source python.sh
else
    echo
fi

echo 'All installation scripts have been executed successfully.'
echo 'For additional installation instructions, please refer to the configs/README.md file.'
