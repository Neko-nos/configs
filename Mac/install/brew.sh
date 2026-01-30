#!/usr/bin/env zsh

# Stop running this script if any error occurs
set -e

# Install Homebrew
# ref: https://brew.sh/
if command -v brew >/dev/null 2>&1; then
    echo "You have already installed Homebrew."
    printf "Update brew? [y/N]: "
    if read -q; then
        # Print a newline using echo because read -q doesn't.
        echo; brew update
    fi
    echo
else
    printf "Install brew? [y/N]: "
    if read -q; then
        echo
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
fi

#######################################
# Install or upgrade a Homebrew formula based on its availability.
# Globals:
#   None
# Arguments:
#   Formula name to check, install, or upgrade.
# Outputs:
#   Writes status messages and prompts to stdout.
# Returns:
#   Exit status of the last brew/read command run.
#######################################
function __install_formula {
    if command -v "${1}" >/dev/null 2>&1; then
        echo "You have already installed ${1}."
        printf "Update ${1}? [y/N]: "
        if read -q; then
            echo; brew upgrade "${1}"
        fi
    # some formulae may fail in the above case (command not found, etc.)
    elif brew list --formula --versions "${1}" >/dev/null 2>&1; then
        echo "You have already installed ${1}."
        printf "Update ${1}? [y/N]: "
        if read -q; then
            echo; brew upgrade "${1}"
        fi
    elif brew list --cask --versions "${1}" >/dev/null 2>&1; then
        echo "You have already installed ${1}."
        printf "Update ${1}? [y/N]: "
        if read -q; then
            echo; brew upgrade --cask "${1}"
        fi
    else
        printf "Install ${1}? [y/N]: "
        if read -q; then
            echo; brew install "${1}"
        fi
    fi
    echo
}

# Install the formulae required by brew_formulae.txt (default to the minimum formulae required to source our .zshrc)
script_dir="${${(%):-%N}:A:h}"
while read -r line
do
    __install_formula "${line}"
done < "${script_dir}/brew_formulae.txt"

# PATH settings
coreutils_path='export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"'
if ! grep -F "${coreutils_path}" ~/.zprofile; then
    echo "${coreutils_path}" >> ~/.zprofile
fi

echo 'Finished Homebrew configuration!'
echo ''
