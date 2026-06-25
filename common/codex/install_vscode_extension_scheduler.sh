#!/usr/bin/env zsh
set -euo pipefail

script_dir="${${(%):-%N}:A:h}"

#######################################
# Install and enable the systemd user timer.
# Globals:
#   HOME
#   XDG_CONFIG_HOME
# Arguments:
#   None
# Outputs:
#   Writes status messages to stdout and stderr
# Returns:
#   0 if the scheduler is installed and enabled, non-zero on systemctl errors.
#######################################
function install_systemd_scheduler() {
    local service_file="${script_dir}/systemd/codex-vscode-extension-root.service"
    local timer_file="${script_dir}/systemd/codex-vscode-extension-root.timer"
    local systemd_user_dir="${XDG_CONFIG_HOME:-${HOME}/.config}/systemd/user"
    local target_service="${systemd_user_dir}/codex-vscode-extension-root.service"
    local target_timer="${systemd_user_dir}/codex-vscode-extension-root.timer"

    mkdir -p "${systemd_user_dir}"
    if [[ ! -e "${target_service}" && ! -L "${target_service}" ]]; then
        ln -s "${service_file}" "${target_service}"
        echo "Created symlink: ${target_service} -> ${service_file}"
    else
        echo "systemd service already exists: ${target_service}"
    fi
    if [[ ! -e "${target_timer}" && ! -L "${target_timer}" ]]; then
        ln -s "${timer_file}" "${target_timer}"
        echo "Created symlink: ${target_timer} -> ${timer_file}"
    else
        echo "systemd timer already exists: ${target_timer}"
    fi

    systemctl --user daemon-reload
    systemctl --user enable --now codex-vscode-extension-root.timer
}

install_systemd_scheduler

echo 'Finished Codex VS Code extension scheduler setup.'
