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
printf 'Do you also want to set up Python configurations? (we use pyenv + poetry.) [y/N]:'
if read -q; then
    echo
    source python.sh
else
    echo
fi

echo 'Finished running all install scripts.'
echo 'Please refer to configs/README.md for further installation instructions.'
