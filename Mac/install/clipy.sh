#!/usr/bin/env zsh

# Stop running this script if any error occurs.
set -euo pipefail

script_dir="${${(%):-%N}:A:h}"
snippets_file="${script_dir}/../clipy/snippets.xml"
snippets_file="${snippets_file:A}"

source "${script_dir}/utils.sh"

if ! command -v brew >/dev/null 2>&1; then
    echo 'Homebrew is required to install Clipy on Mac.'
    echo 'Skipping Clipy installation.'
    echo
else
    __install_formula clipy

    echo "Import ${snippets_file} from Clipy's Manage Snippets window."
    echo

    echo 'Finished Clipy installation!'
    echo
fi
