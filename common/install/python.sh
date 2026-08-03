#!/bin/zsh

# Stop running this script if any error occurs
set -e

script_dir="${${(%):-%N}:A:h}"

source "${script_dir}/utils.sh"

if command -v uv >/dev/null 2>&1; then
    echo 'You have already installed uv.'
    if __confirm 'Do you want to update uv? [y/N]: '; then
        uv self update
    fi
else
    if __confirm 'Do you want to install uv? [y/N]: '; then
        # ref: https://docs.astral.sh/uv/getting-started/installation/
        curl -LsSf https://astral.sh/uv/install.sh | sh
    fi
fi

echo 'Finished Python configuration!'
