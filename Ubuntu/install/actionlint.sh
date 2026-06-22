#!/bin/zsh

# Stop running this script if any error occurs
set -e

script_dir="${${(%):-%N}:A:h}"

source "${script_dir}/utils.sh"

#######################################
# Install or update the actionlint prebuilt binary.
# Globals:
#   HOME
# Arguments:
#   None
# Outputs:
#   Writes installer output to stdout and stderr.
#######################################
function __install_actionlint_binary() {
    local install_dir="${HOME}/.local/bin"
    local download_script_url='https://raw.githubusercontent.com/rhysd/actionlint/main/scripts/download-actionlint.bash'

    mkdir -p "${install_dir}"

    if command -v actionlint >/dev/null 2>&1; then
        echo 'You have already installed actionlint.'
        if __confirm 'Update actionlint? [y/N]: '; then
            curl -sSfL "${download_script_url}" | bash -s -- latest "${install_dir}"
        fi
    elif __confirm 'Install actionlint? [y/N]: '; then
        curl -sSfL "${download_script_url}" | bash -s -- latest "${install_dir}"
    fi

    echo 'Finished actionlint installation!'
    echo ''
}

# The upstream installer is a Bash script downloaded with curl.
if command -v bash >/dev/null 2>&1; then
    echo 'You have already installed bash.'
    echo
else
    __install_package bash
fi

if command -v curl >/dev/null 2>&1; then
    echo 'You have already installed curl.'
    echo
else
    __install_package curl
fi

if command -v bash >/dev/null 2>&1 && command -v curl >/dev/null 2>&1; then
    __install_actionlint_binary
else
    echo 'bash and curl are required to install actionlint.'
    echo 'Skipping actionlint installation.'
    echo
fi
