#!/bin/zsh

# Stop running this script if any error occurs
set -e

script_dir="${${(%):-%N}:A:h}"
repo_vscodedir="${script_dir}/../../VSCode"
repo_vscodedir="${repo_vscodedir:A}"

source "${script_dir}/utils.sh"

# ref: https://code.visualstudio.com/docs/configure/settings#_settings-file-locations
vscode_user_dir="${VSCODE_USER_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/Code/User}"

if [[ -z "${VSCODE_USER_DIR:-}" ]] && command -v cmd.exe >/dev/null 2>&1 && command -v wslpath >/dev/null 2>&1; then
    windows_appdata="$(cmd.exe /C 'echo %APPDATA%' 2>/dev/null)"
    windows_appdata="${windows_appdata//$'\r'/}"
    if [[ -n "${windows_appdata}" ]]; then
        vscode_user_dir="$(wslpath -u "${windows_appdata}\\Code\\User")"
    fi
fi

mkdir -p "${vscode_user_dir}"

__install_repo_path "${repo_vscodedir}/settings.json" "${vscode_user_dir}/settings.json" 'VSCode settings.json' link
__install_repo_path "${repo_vscodedir}/keybindings.json" "${vscode_user_dir}/keybindings.json" 'VSCode keybindings.json' link

echo 'Finished VSCode configuration!'
echo ''
