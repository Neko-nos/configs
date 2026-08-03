#!/bin/zsh

# Stop running this script if any error occurs
set -e

script_dir="${${(%):-%N}:A:h}"
repo_vscodedir="${script_dir}/../../VSCode"
repo_vscodedir="${repo_vscodedir:A}"

source "${script_dir}/utils.sh"

# ref: https://microsoft.github.io/vscode-essentials/en/01-getting-started.html
if command -v winget.exe >/dev/null 2>&1; then
    # WSL interoperability runs this Windows executable as the active Windows user.
    __install_winget_package Microsoft.VisualStudioCode 'Visual Studio Code'
else
    echo 'WinGet is required to install Visual Studio Code on Windows.'
    echo 'Skipping Visual Studio Code installation.'
    echo
fi

# ref: https://code.visualstudio.com/docs/configure/settings#_settings-file-locations
vscode_user_dir="${VSCODE_USER_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/Code/User}"
vscode_install_mode='link'

if [[ -z "${VSCODE_USER_DIR:-}" ]] && command -v cmd.exe >/dev/null 2>&1 && command -v wslpath >/dev/null 2>&1; then
    windows_appdata="$(cmd.exe /C 'echo %APPDATA%' 2>/dev/null)"
    windows_appdata="${windows_appdata//$'\r'/}"
    if [[ -n "${windows_appdata}" ]]; then
        vscode_user_dir="$(wslpath -u "${windows_appdata}\\Code\\User")"
        # Windows VS Code cannot reliably read WSL-created symlinks in AppData.
        vscode_install_mode='copy'
    fi
fi

mkdir -p "${vscode_user_dir}"

__install_repo_path "${repo_vscodedir}/settings.json" "${vscode_user_dir}/settings.json" 'VSCode settings.json' "${vscode_install_mode}"
__install_repo_path "${repo_vscodedir}/keybindings.json" "${vscode_user_dir}/keybindings.json" 'VSCode keybindings.json' "${vscode_install_mode}"

echo 'Finished VSCode configuration!'
echo ''
