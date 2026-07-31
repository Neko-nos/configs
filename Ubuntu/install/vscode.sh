#!/bin/zsh

# Stop running this script if any error occurs
set -e

script_dir="${${(%):-%N}:A:h}"
repo_vscodedir="${script_dir}/../../VSCode"
repo_vscodedir="${repo_vscodedir:A}"
# ref: https://code.visualstudio.com/docs/configure/settings#_settings-file-locations
vscode_user_dir="${VSCODE_USER_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/Code/User}"

source "${script_dir}/utils.sh"

if [[ ! -f /etc/apt/sources.list.d/vscode.sources ]]; then
    # ref: https://code.visualstudio.com/docs/setup/linux
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
        | sudo gpg --dearmor -o /usr/share/keyrings/microsoft.gpg
    sudo tee /etc/apt/sources.list.d/vscode.sources >/dev/null <<'EOF'
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64,arm64,armhf
Signed-By: /usr/share/keyrings/microsoft.gpg
EOF
fi
__install_package code

mkdir -p "${vscode_user_dir}"

__install_repo_path "${repo_vscodedir}/settings.json" "${vscode_user_dir}/settings.json" 'VSCode settings.json' link
__install_repo_path "${repo_vscodedir}/keybindings.json" "${vscode_user_dir}/keybindings.json" 'VSCode keybindings.json' link

echo 'Finished VSCode configuration!'
echo ''
