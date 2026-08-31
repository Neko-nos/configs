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
# Activation prints shell assignments that must run here to update PATH.
eval "$(spack env activate --sh "${HOME}/spack/var/spack/environments/$(spack arch)/server")"

install_uv
# Use uv tool instead of apt so the commands can be installed without sudo.
uv tool install gdown
uv tool install hf
uv tool install icdiff
uv tool install ruff
if [[ "${1:-bash}" == "bash" ]]; then
    install_gitstatus
elif [[ "${1:-bash}" != "zsh" ]]; then
    printf "Expected shell argument to be bash or zsh; received: %s\n" "${1}" >&2
    exit 1
fi

echo "Finished command installation!"
