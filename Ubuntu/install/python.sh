#!/bin/zsh

# Stop running this script if any error occurs
set -e

printf 'Which do you want to use, uv or pyenv + poetry? [uv/pp]: '
read choice

if [[ "${choice}" == 'uv' ]]; then
    echo 'You selected uv.'
    if [[ -x "$(where uv)" ]]; then
        echo 'You have already installed uv.'
    else
        printf 'Do you want to install uv? [y/N]: '
        if read -q; then
            # ref: https://docs.astral.sh/uv/getting-started/installation/
            curl -LsSf https://astral.sh/uv/install.sh | sh
            echo '# ref: https://docs.astral.sh/uv/getting-started/installation/' >> ~/.zshrc
            echo 'if [[ -x $(which -p uv) ]]; then' >> ~/.zshrc
            echo '    eval "$(uv generate-shell-completion zsh)"' >> ~/.zshrc
            echo '    eval "$(uvx --generate-shell-completion zsh)"' >> ~/.zshrc
            echo 'fi' >> ~/.zshrc
        else
            echo
        fi
    fi
elif [[ "${choice}" == 'pp' ]]; then
    echo 'You selected pyenv + poetry.'
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

    # Poetry
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
else
    echo "Invalid selection! You typed ${choice}, but it should be either 'uv' or 'pp'."
    echo 'Please run the script again and select either uv or pp.'
    exit 1
fi

echo 'Finished Python configuration!'
echo ''
