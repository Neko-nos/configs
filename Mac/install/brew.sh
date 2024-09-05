#!/usr/bin/env zsh

# Stop running this script if any error occurs
set -e

# Install Homebrew
# ref: https://brew.sh/
if [[ -x "$(where brew)" ]]; then
    echo "You have already installed Homebrew."
    printf "Update brew? [y/N]: "
    if read -q; then
        echo; brew update
    fi
    echo
else
    printf "Install brew? [y/N]: "
    if read -q; then
        echo
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # Users would rather cusomize our dotfiles, so we don't use our .zprofile
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
fi

# Now, install the tools that can be installed via brew
# define this common function to install or update a brew formula
function install_formula {
    if [[ -x "$(where ${1})" ]]; then
        echo "You have already installed ${1}."
        printf "Update ${1}? [y/N]: "
        if read -q; then
            echo; brew upgrade ${1}
        fi
    # some formulae may fail in the above case (command not found, etc.)
    # brew info command takes much longer time than where command, so we use it only after the above case fails
    elif [[ ! "`brew info ${1} | grep "Not installed"`" ]]; then
        echo "You have already installed ${1}."
        printf "Update ${1}? [y/N]: "
        if read -q; then
            echo; brew upgrade ${1}
        fi
    else
        printf "Install ${1}? [y/N]: "
        if read -q; then
            echo; brew install ${1}
        fi
    fi
    echo
}

# Install the formulae required by .zshrc
cd "$(dirname "$0")"
while read line
do
    install_formula ${line}
done < "brew_formulae.txt"

# PATH settings
coreutils_path='export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"'
if ! grep -q "$coreutils_path" ~/.zprofile; then
    echo  >> ~/.zprofile
    export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
fi

echo 'Finished Homebrew configuration!'
echo ''
