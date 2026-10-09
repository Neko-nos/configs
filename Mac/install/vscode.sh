#!/usr/bin/env zsh

set -euo pipefail

script_dir="${${(%):-%N}:A:h}"
repo_vscodedir="${script_dir}/../../VSCode"
repo_vscodedir="${repo_vscodedir:A}"
# ref: https://code.visualstudio.com/docs/configure/settings#_settings-file-locations
vscode_user_dir="${VSCODE_USER_DIR:-$HOME/Library/Application Support/Code/User}"
vscode_extensions_dir="${VSCODE_EXTENSIONS_DIR:-$HOME/.vscode/extensions}"
vscode_argv_path="${VSCODE_ARGV_PATH:-$HOME/.vscode/argv.json}"

source "${script_dir}/utils.sh"

#######################################
# Ask before building and installing a custom VSCode extension from its repository.
# Globals:
#   HOME: Used for the repository root.
#   vscode_extensions_dir: Destination for installed extensions.
# Arguments:
#   Extension name.
#   Git repository URL.
# Outputs:
#   Writes a confirmation prompt and installation progress to stdout and stderr.
# Returns:
#   0 if the user declines installation.
#######################################
function __install_vscode_extension() {
    local extension_name="${1}"
    local repository_url="${2}"
    local repository_dir="${HOME}/repos/${extension_name}"
    repository_dir="${repository_dir:A}"

    if ! __confirm "Install ${extension_name} extension? [y/N]: "; then
        echo "Skipping ${extension_name} installation."
        return 0
    fi

    if [[ ! -d "${repository_dir}" ]]; then
        mkdir -p "${repository_dir:h}"
        git clone "${repository_url}" "${repository_dir}"
    fi

    (
        cd "${repository_dir}"
        npm ci
        npm run package -- --out "${repository_dir}/${extension_name}.vsix"
    )
    code --extensions-dir "${vscode_extensions_dir}" --install-extension "${repository_dir}/${extension_name}.vsix"
}

if command -v brew >/dev/null 2>&1; then
    __install_formula visual-studio-code '/Applications/Visual Studio Code.app'
else
    echo 'Homebrew is required to install Visual Studio Code on Mac.'
    echo 'Skipping Visual Studio Code installation.'
    echo
fi

mkdir -p "${vscode_user_dir}" "${vscode_extensions_dir}" "${vscode_argv_path:h}"

__install_repo_path "${repo_vscodedir}/settings.json" "${vscode_user_dir}/settings.json" 'VSCode settings.json' link
__install_repo_path "${repo_vscodedir}/keybindings.json" "${vscode_user_dir}/keybindings.json" 'VSCode keybindings.json' link
__install_repo_path "${repo_vscodedir}/argv.json" "${vscode_argv_path}" 'VSCode argv.json' link

__install_vscode_extension zsh-language-server https://github.com/Neko-nos/zsh-language-server.git
__install_vscode_extension smart-terminal-paste https://github.com/Neko-nos/smart-terminal-paste.git
if __confirm 'Install browser-click-routing extension? [y/N]: '; then
    (
        cd "${repo_vscodedir}/extensions/browser-click-routing"
        npm ci
        npm run package -- --out browser-click-routing.vsix
        code --extensions-dir "${vscode_extensions_dir}" --install-extension browser-click-routing.vsix
    )
fi

echo 'Finished VSCode configuration!'
echo 'For Cmd-click / Ctrl-click URL routing, also run Mac/install/hammerspoon.sh and restart VSCode.'
echo ''
