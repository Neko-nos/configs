#!/bin/zsh

# Stop running this script if any error occurs
set -e

script_dir="${${(%):-%N}:A:h}"

source "${script_dir}/utils.sh"

# Respect npm installed by nvm or other non-apt installers.
if command -v npm >/dev/null 2>&1; then
    echo 'You have already installed npm.'
    echo
else
    __install_package npm
fi

if command -v npm >/dev/null 2>&1; then
    if command -v markdownlint-cli2 >/dev/null 2>&1; then
        echo 'You have already installed markdownlint-cli2.'
        if __confirm 'Update markdownlint-cli2? [y/N]: '; then
            npm install --global markdownlint-cli2
        fi
    elif __confirm 'Install markdownlint-cli2? [y/N]: '; then
        npm install --global markdownlint-cli2
    fi

    echo 'Finished markdownlint-cli2 installation!'
    echo ''
else
    echo 'npm is required to install markdownlint-cli2.'
    echo 'Skipping markdownlint-cli2 installation.'
    echo
fi
