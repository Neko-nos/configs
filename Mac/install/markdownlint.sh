#!/usr/bin/env zsh

# Stop running this script if any error occurs
set -e

script_dir="${${(%):-%N}:A:h}"

source "${script_dir}/utils.sh"

if command -v brew >/dev/null 2>&1; then
    __install_formula markdownlint-cli2
    echo 'Finished markdownlint-cli2 installation!'
    echo ''
else
    echo 'Homebrew is required to install markdownlint-cli2 on Mac.'
    echo 'Skipping markdownlint-cli2 installation.'
    echo
fi
