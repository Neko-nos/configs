#!/bin/bash

set -euo pipefail

script_dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${script_dir}/utils.sh"

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
# Install or update ShellCheck without root privileges.
# Arguments:
#   None
# Outputs:
#   Writes installer output to stdout and stderr.
# Returns:
#   0 if shellcheck is available after installation or update, non-zero otherwise.
#######################################
function install_shellcheck() {
    local cache_dir="${XDG_CACHE_HOME:-${HOME}/.cache}/server-install"
    local platform
    local package_name archive_path extract_dir

    if command -v shellcheck >/dev/null 2>&1; then
        if ! __confirm "Do you want to update shellcheck? [y/N]: "; then
            echo "Skipping shellcheck update."
            return 0
        fi
        echo "Updating shellcheck."
    else
        echo "Installing shellcheck."
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

#######################################
# Install or update fzf without root privileges.
# Arguments:
#   None
# Outputs:
#   Writes installer output to stdout and stderr.
# Returns:
#   0 if fzf is available after installation or update, non-zero otherwise.
#######################################
function install_fzf() {
    local install_dir="${HOME}/.fzf"
    local link_path="${HOME}/.local/bin/fzf"

    if [[ -d "${install_dir}/.git" ]]; then
        if command -v fzf >/dev/null 2>&1 && ! __confirm "Do you want to update fzf? [y/N]: "; then
            echo "Skipping fzf update."
            return 0
        fi
        echo "Updating fzf."
        git -C "${install_dir}" pull --ff-only
    elif command -v fzf >/dev/null 2>&1; then
        printf "fzf is installed outside %s; use its package manager to update it.\n" "${install_dir}"
        return 0
    elif [[ -e "${install_dir}" ]]; then
        printf "fzf installation path exists but is not a Git checkout: %s\n" "${install_dir}" >&2
        return 1
    else
        echo "Installing fzf."
        git clone --depth 1 https://github.com/junegunn/fzf.git "${install_dir}"
    fi

    # Shell integration is managed in this repository, so only let the
    # upstream installer download its binary.
    "${install_dir}/install" --bin
    if [[ ! -e "${link_path}" && ! -L "${link_path}" ]]; then
        ln -s "${install_dir}/bin/fzf" "${link_path}"
    fi
    return 0
}

#######################################
# Install colordiff without root privileges.
# Arguments:
#   None
# Outputs:
#   Writes download and installation status to stdout and stderr.
# Returns:
#   0 if colordiff is available, non-zero otherwise.
#######################################
function install_colordiff() {
    local cache_dir="${XDG_CACHE_HOME:-${HOME}/.cache}/server-install"
    local archive_path="${cache_dir}/colordiff-latest.tar.gz"
    local extract_dir
    local user_bin_dir="${HOME}/.local/bin"

    if command -v colordiff >/dev/null 2>&1; then
        echo "You have already installed colordiff."
        return 0
    fi

    echo "Installing colordiff."
    mkdir -p "${cache_dir}" "${user_bin_dir}"
    extract_dir="$(mktemp -d "${cache_dir}/colordiff.XXXXXX")"
    wget "https://www.colordiff.org/colordiff-latest.tar.gz" -O "${archive_path}"
    tar -xzf "${archive_path}" -C "${extract_dir}" --strip-components 1
    cp "${extract_dir}/colordiff.pl" "${user_bin_dir}/colordiff"
    chmod 755 "${user_bin_dir}/colordiff"
    return 0
}

#######################################
# Install gitstatus for fast Git information in the Bash prompt.
# Arguments:
#   None
# Outputs:
#   Writes installation status and Git output to stdout and stderr.
# Returns:
#   0 if gitstatus is installed, non-zero otherwise.
#######################################
function install_gitstatus() {
    local install_dir="${XDG_DATA_HOME:-${HOME}/.local/share}/gitstatus"

    if ((BASH_VERSINFO[0] < 4)); then
        printf "gitstatus requires Bash 4 or newer; found %s.\n" "${BASH_VERSION}" >&2
        return 1
    fi
    if [[ -d "${install_dir}/.git" ]]; then
        echo "You have already installed gitstatus."
        return 0
    fi
    if [[ -e "${install_dir}" ]]; then
        printf "gitstatus installation path exists but is not a Git checkout: %s\n" "${install_dir}" >&2
        return 1
    fi

    echo "Installing gitstatus."
    mkdir -p "$(dirname "${install_dir}")"
    git clone --depth 1 https://github.com/romkatv/gitstatus.git "${install_dir}"
    return 0
}

mkdir -p "${HOME}/.local/bin"
export PATH="${HOME}/.local/bin:${PATH}"

install_uv
# Use uv tool instead of apt so the commands can be installed without sudo.
uv tool install gdown
uv tool install hf
uv tool install icdiff
install_fzf
install_gitstatus
install_shellcheck

echo "Finished command installation!"
