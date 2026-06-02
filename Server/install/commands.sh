#!/bin/bash

set -euo pipefail

#######################################
# Install uv and uvx without root privileges.
# Arguments:
#   None
# Outputs:
#   Writes installer output to stdout and stderr.
# Returns:
#   0 if uv and uvx are available after installation, non-zero otherwise.
#######################################
function install_uv() {
    if command -v uv >/dev/null 2>&1 && command -v uvx >/dev/null 2>&1; then
        echo "You have already installed uv and uvx."
        return 0
    fi

    curl -LsSf https://astral.sh/uv/install.sh | sh
    return 0
}

#######################################
# Resolve the ShellCheck release asset platform for this machine.
# Arguments:
#   None
# Outputs:
#   Writes the ShellCheck asset platform to stdout.
# Returns:
#   0 if the platform is supported, non-zero otherwise.
#######################################
function __shellcheck_platform() {
    case "$(uname -m)" in
        x86_64 | amd64)
            printf "linux.x86_64\n"
            ;;
        aarch64 | arm64)
            printf "linux.aarch64\n"
            ;;
        *)
            printf "Unsupported ShellCheck platform: %s\n" "$(uname -m)" >&2
            return 1
            ;;
    esac
    return 0
}

#######################################
# Install ShellCheck without root privileges.
# Arguments:
#   None
# Outputs:
#   Writes installer output to stdout and stderr.
# Returns:
#   0 if shellcheck is available after installation, non-zero otherwise.
#######################################
function install_shellcheck() {
    local cache_dir="${XDG_CACHE_HOME:-${HOME}/.cache}/server-install"
    local platform
    local package_name archive_path extract_dir

    if command -v shellcheck >/dev/null 2>&1; then
        echo "You have already installed shellcheck."
        return 0
    fi

    platform="$(__shellcheck_platform)"
    package_name="shellcheck-latest.${platform}"
    archive_path="${cache_dir}/${package_name}.tar.xz"
    extract_dir="${cache_dir}/${package_name}"

    mkdir -p "${cache_dir}" "${HOME}/.local/bin" "${extract_dir}"
    # Download the standalone binary instead of using sudo apt install.
    wget "https://github.com/koalaman/shellcheck/releases/download/latest/${package_name}.tar.xz" -O "${archive_path}"
    tar -xJf "${archive_path}" -C "${extract_dir}" --strip-components 1
    # Copy the binary so shellcheck remains available even if the download
    # cache is cleaned later.
    cp "${extract_dir}/shellcheck" "${HOME}/.local/bin/shellcheck"
    chmod 755 "${HOME}/.local/bin/shellcheck"
    return 0
}

mkdir -p "${HOME}/.local/bin"
export PATH="${HOME}/.local/bin:${PATH}"

install_uv
# Use uv tool instead of apt so gdown can be installed without sudo.
uv tool install gdown
install_shellcheck

echo "Finished command installation!"
