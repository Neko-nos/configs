#!/usr/bin/env zsh

set -euo pipefail

script_dir="${${(%):-%N}:A:h}"
repo_hammerspoon_dir="${script_dir}/../hammerspoon"
repo_hammerspoon_dir="${repo_hammerspoon_dir:A}"
hammerspoon_config_dir="${HAMMERSPOON_CONFIG_DIR:-${HOME}/.hammerspoon}"

source "${script_dir}/utils.sh"

if command -v brew >/dev/null 2>&1; then
    __install_formula hammerspoon
else
    echo 'Homebrew is required to install Hammerspoon from this script.'
    echo 'Skipping Hammerspoon installation.'
fi

mkdir -p "${hammerspoon_config_dir}"
__install_repo_path \
    "${repo_hammerspoon_dir}/init.lua" \
    "${hammerspoon_config_dir}/init.lua" \
    'Hammerspoon init.lua' \
    link

echo 'Finished Hammerspoon configuration!'
echo ''
