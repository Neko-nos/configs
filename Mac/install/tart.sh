#!/usr/bin/env zsh

set -euo pipefail

tart_script_dir="${${(%):-%N}:A:h}"

source "${tart_script_dir}/utils.sh"

if [[ "$(uname -m)" != 'arm64' ]]; then
    echo 'Tart requires an Apple silicon Mac.'
    echo 'Skipping Tart installation.'
    echo
elif command -v brew >/dev/null 2>&1; then
    # ref: https://developer.hashicorp.com/packer/tutorials/docker-get-started/get-started-install-cli
    brew tap hashicorp/tap
    __install_formula hashicorp/tap/packer
    # Homebrew does not automatically trust dependencies from non-official taps.
    brew trust --formula openai/tools/tart openai/tools/softnet
    __install_formula openai/tools/tart
    if command -v uv >/dev/null 2>&1; then
        uv tool install vncdotool
    elif [[ -x "${HOME}/.local/bin/uv" ]]; then
        "${HOME}/.local/bin/uv" tool install vncdotool
    else
        echo 'uv is required to install vncdotool (vncdo). Run common/install/python.sh, then run: uv tool install vncdotool'
        echo
    fi
else
    echo 'Homebrew is required to install Tart on Mac.'
    echo 'Skipping Tart installation.'
    echo
fi

unset -v tart_script_dir
