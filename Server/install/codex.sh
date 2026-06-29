#!/bin/bash

set -euo pipefail

script_dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${script_dir}/utils.sh"

#######################################
# Install bwrap by extracting Ubuntu's bubblewrap package into ~/.local.
# Arguments:
#   Cache directory.
#   User-local bin directory.
# Outputs:
#   Writes apt, dpkg-deb, and status output to stdout and stderr.
# Returns:
#   0 if bwrap is available after installation, non-zero otherwise.
#######################################
function install_bwrap() {
    local cache_dir="${1}"
    local user_bin_dir="${2}"
    local download_dir extract_dir deb_path

    if command -v bwrap >/dev/null 2>&1; then
        echo "You have already installed bwrap."
        return 0
    fi

    mkdir -p "${cache_dir}" "${user_bin_dir}"
    download_dir="$(mktemp -d "${cache_dir}/bubblewrap-download.XXXXXX")"
    extract_dir="$(mktemp -d "${cache_dir}/bubblewrap-extract.XXXXXX")"

    (
        cd "${download_dir}"
        # Use Ubuntu's packaged binary because bubblewrap's source build depends
        # on a less common toolchain, while apt-get download itself is rootless.
        apt-get download bubblewrap
    )

    deb_path="$(find "${download_dir}" -maxdepth 1 -type f -name "bubblewrap_*.deb" -print | sort | tail -n 1)"
    if [[ -z "${deb_path}" ]]; then
        echo "Failed to download the Ubuntu bubblewrap package." >&2
        return 1
    fi

    dpkg-deb -x "${deb_path}" "${extract_dir}"
    if [[ ! -x "${extract_dir}/usr/bin/bwrap" ]]; then
        echo "Downloaded bubblewrap package did not contain usr/bin/bwrap." >&2
        return 1
    fi

    cp "${extract_dir}/usr/bin/bwrap" "${user_bin_dir}/bwrap"
    chmod 755 "${user_bin_dir}/bwrap"
    bwrap --version
}

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
# Link this repository's Codex configuration into CODEX_HOME.
# Arguments:
#   Codex home directory.
#   Repository Codex configuration directory.
# Outputs:
#   Writes symlink status messages to stdout.
# Returns:
#   0 if configuration is installed, non-zero otherwise.
#######################################
function install_codex_configuration() {
    local codex_home="${1}"
    local common_codex_dir="${2}"

    mkdir -p "${codex_home}"
    __install_symlink "${common_codex_dir}/AGENTS.md" "${codex_home}/AGENTS.md" "Codex AGENTS.md"
    __install_symlink "${common_codex_dir}/config.toml" "${codex_home}/config.toml" "Codex config.toml"
}

#######################################
# Install Codex CLI and its server-side dependencies without root privileges.
# Arguments:
#   None
# Outputs:
#   Writes installation output to stdout and stderr.
#######################################
function main() {
    local repo_root cache_dir user_bin_dir codex_home

    repo_root="$(readlink -f "${script_dir}/../..")"
    cache_dir="${XDG_CACHE_HOME:-${HOME}/.cache}/server-install"
    user_bin_dir="${HOME}/.local/bin"
    codex_home="${HOME}/.codex"

    export PATH="${user_bin_dir}:${PATH}"

    install_bwrap "${cache_dir}" "${user_bin_dir}"
    install_codex_cli "${cache_dir}" "${user_bin_dir}" "${codex_home}"
    install_codex_configuration "${codex_home}" "${repo_root}/common/codex"
}

main

echo "Finished Codex server installation!"
