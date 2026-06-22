#!/usr/bin/env zsh

# Stop running this script if any error occurs
set -e

script_dir="${${(%):-%N}:A:h}"

source "${script_dir}/utils.sh"

if command -v brew >/dev/null 2>&1; then
    __install_formula actionlint
    echo 'Finished actionlint installation!'
    echo ''
else
    echo 'Homebrew is required to install actionlint on Mac.'
    echo 'Skipping actionlint installation.'
    echo
fi
