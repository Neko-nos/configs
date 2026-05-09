#!/usr/bin/env zsh

# Stop running this script if any error occurs
set -e

script_dir="${${(%):-%N}:A:h}"

source "${script_dir}/utils.sh"

# Install Homebrew
# ref: https://brew.sh/
if command -v brew >/dev/null 2>&1; then
    echo "You have already installed Homebrew."
    if __confirm "Update brew? [y/N]: "; then
        brew update
    fi
    echo
else
    if __confirm "Install brew? [y/N]: "; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
fi

# Install the formulae required by brew_formulae.txt (default to the minimum formulae required to source our .zshrc)
# Read package names from a dedicated file descriptor so interactive prompts can
# keep using the terminal stdin even after a brew command runs.
exec 3< "${script_dir}/brew_formulae.txt"
while IFS= read -r line <&3
do
    # We allow blank lines and comments (#) in brew_formulae.txt.
    [[ -z "${line}" || "${line}" == \#* ]] && continue
    __install_formula "${line}"
done
exec 3<&-

# PATH settings
coreutils_path='export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"'
if ! grep -F "${coreutils_path}" ~/.zprofile; then
    echo "${coreutils_path}" >> ~/.zprofile
fi

echo 'Finished Homebrew configuration!'
echo ''
