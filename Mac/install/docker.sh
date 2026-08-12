#!/usr/bin/env zsh

# Stop running this script if any error occurs
set -e

docker_script_dir="${${(%):-%N}:A:h}"

source "${docker_script_dir}/utils.sh"

if command -v brew >/dev/null 2>&1; then
    __install_formula docker-desktop '/Applications/Docker.app'

    if brew list --cask --versions docker-desktop >/dev/null 2>&1 || [[ -d '/Applications/Docker.app' ]]; then
        if [[ "$(uname -m)" == 'arm64' ]]; then
            if pkgutil --pkg-info com.apple.pkg.RosettaUpdateAuto >/dev/null 2>&1; then
                echo 'You have already installed Rosetta 2.'
            elif __confirm 'Install Rosetta 2? [y/N]: '; then
                softwareupdate --install-rosetta
            else
                echo 'Skipping Rosetta 2 installation.'
            fi
            echo
        fi

        echo 'Start Docker Desktop once to accept its license terms and select its settings.'
        echo 'Finished Docker Desktop installation!'
        echo
    fi
else
    echo 'Homebrew is required to install Docker Desktop on Mac.'
    echo 'Skipping Docker Desktop installation.'
    echo
fi

unset -v docker_script_dir
