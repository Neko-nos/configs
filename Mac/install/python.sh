#!/usr/bin/env zsh

# Stop running this script if any error occurs
set -e

# Pyenv
if [[ -x "$(where pyenv)" ]]; then
    echo 'You have already installed pyenv.'
else
    printf 'Do you want to install pyenv? [y/N]: '
    if read -q; then
        echo; git clone https://github.com/pyenv/pyenv.git ~/.pyenv
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$(pyenv init -)"
        echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zprofile
        echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zprofile
        echo 'eval "$(pyenv init -)"' >> ~/.zprofile
    else
        echo
    fi
fi

if [[ -x "$(where poetry)" ]]; then
    echo 'You have already installed Poetry.'
else
    printf 'Do you want to install Poetry? [y/N]: '
    if read -q; then
        echo; curl -sSL https://install.python-poetry.org | python -
        export PATH="$HOME/.local/bin:$PATH"
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zprofile
        # Some default settings are not useful
        poetry config virtualenvs.in-project true
    else
        echo
    fi
fi

echo 'Finished Python configuration!'
echo ''
