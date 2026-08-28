#!/bin/bash

set -euo pipefail

script_dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

#######################################
# Install or update Codex CLI with the official rootless installer.
# Arguments:
#   Cache directory.
#   Codex CLI installation directory.
#   Codex home directory.
# Outputs:
#   Writes installer output to stdout and stderr.
# Returns:
#   0 if codex is available after installation, non-zero otherwise.
#######################################
function install_codex_cli() {
    local cache_dir="${1}"
    local codex_install_dir="${2}"
    local codex_home="${3}"
    local installer_path="${cache_dir}/codex-install.sh"

    mkdir -p "${cache_dir}" "${codex_install_dir}" "${codex_home}"
    curl -fsSL "https://raw.githubusercontent.com/openai/codex/refs/heads/main/scripts/install/install.sh" -o "${installer_path}"

    CODEX_INSTALL_DIR="${codex_install_dir}" \
    CODEX_HOME="${codex_home}" \
    CODEX_NON_INTERACTIVE=true \
    sh "${installer_path}"

    command -v codex >/dev/null 2>&1
}

#######################################
# Install Codex CLI and its configurations without root privileges.
# Arguments:
#   None
# Outputs:
#   Writes installation output to stdout and stderr.
#######################################
function main() {
    local repo_root cache_dir user_bin_dir codex_home codex_sqlite_home

    repo_root="$(readlink -f "${script_dir}/../..")"
    cache_dir="${XDG_CACHE_HOME:-${HOME}/.cache}/server-install"
    user_bin_dir="${HOME}/.local/bin"
    codex_home="${HOME}/.codex"
    codex_sqlite_home="/var/tmp/${USER}/codex"

    export PATH="${user_bin_dir}:${PATH}"

    install_codex_cli "${cache_dir}" "${user_bin_dir}" "${codex_home}"
    CODEX_HOME="${codex_home}" \
    CODEX_SQLITE_HOME="${codex_sqlite_home}" \
    zsh "${repo_root}/common/install/codex.sh"
}

main

echo "Finished Codex server installation!"
