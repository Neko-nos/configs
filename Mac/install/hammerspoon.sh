#!/usr/bin/env zsh

set -euo pipefail

script_dir="${${(%):-%N}:A:h}"
repo_hammerspoon_dir="${script_dir}/../hammerspoon"
repo_hammerspoon_dir="${repo_hammerspoon_dir:A}"
hammerspoon_config_dir="${HAMMERSPOON_CONFIG_DIR:-${HOME}/.hammerspoon}"

source "${script_dir}/utils.sh"

if command -v brew >/dev/null 2>&1; then
    __install_formula hammerspoon '/Applications/Hammerspoon.app'
    __install_formula luacheck
    __install_formula stylua
else
    echo 'Homebrew is required to install Hammerspoon, Luacheck, and StyLua from this script.'
    echo 'Skipping Hammerspoon and Lua tooling installation.'
fi

mkdir -p "${hammerspoon_config_dir}"
for config_file in "${repo_hammerspoon_dir}"/*.lua; do
    __install_repo_path \
        "${config_file}" \
        "${hammerspoon_config_dir}/${config_file:t}" \
        "Hammerspoon ${config_file:t}" \
        link
done

# init.lua calls hs.autoLaunch(true), so Hammerspoon registers itself after this first launch.
__open_application_for_setup Hammerspoon '/Applications/Hammerspoon.app'

echo 'Finished Hammerspoon configuration!'
echo ''
