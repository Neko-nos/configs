#!/usr/bin/env zsh

# Stop running this script if any error occurs
set -e

script_dir="${${(%):-%N}:A:h}"
repo_vscodedir="${script_dir}/../../VSCode"
repo_vscodedir="${repo_vscodedir:A}"
# ref: https://code.visualstudio.com/docs/configure/settings#_settings-file-locations
vscode_user_dir="${VSCODE_USER_DIR:-$HOME/Library/Application Support/Code/User}"
vscode_extensions_dir="${VSCODE_EXTENSIONS_DIR:-$HOME/.vscode/extensions}"

source "${script_dir}/utils.sh"

if command -v brew >/dev/null 2>&1; then
    __install_formula visual-studio-code
else
    echo 'Homebrew is required to install Visual Studio Code on Mac.'
    echo 'Skipping Visual Studio Code installation.'
    echo
fi

mkdir -p "${vscode_user_dir}" "${vscode_extensions_dir}"

__install_repo_path "${repo_vscodedir}/settings.json" "${vscode_user_dir}/settings.json" 'VSCode settings.json' link
__install_repo_path "${repo_vscodedir}/keybindings.json" "${vscode_user_dir}/keybindings.json" 'VSCode keybindings.json' link
__install_repo_path "${repo_vscodedir}/extensions/smart-terminal-paste" "${vscode_extensions_dir}/smart-terminal-paste" 'Smart Terminal Paste extension' link

echo 'Finished VSCode configuration!'
echo ''
