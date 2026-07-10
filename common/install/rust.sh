#!/bin/zsh

# Stop running this script if any error occurs
set -e

#######################################
# Install rustup with a minimal Rust toolchain when it is missing.
# Globals:
#   HOME
#   PATH
# Arguments:
#   None
# Outputs:
#   Writes rustup installer output to stdout and stderr.
# Returns:
#   0 if rustup is available after installation, non-zero otherwise.
#######################################
function install_rustup() {
    if command -v rustup >/dev/null 2>&1; then
        echo 'You have already installed rustup.'
        return 0
    fi

    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    export PATH="${HOME}/.cargo/bin:${PATH}"
    command -v rustup >/dev/null 2>&1
}

install_rustup

echo 'Finished Rust configuration!'
echo ''
