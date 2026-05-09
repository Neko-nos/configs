#!/bin/zsh

script_dir="${${(%):-%N}:A:h}"
common_install_dir="${script_dir}/../../common/install"
common_install_dir="${common_install_dir:A}"

source "${common_install_dir}/utils.sh"

#######################################
# Install a package via apt-get if it is not already installed.
# Globals:
#   None
# Arguments:
#   Package name to check and install.
# Outputs:
#   Writes status messages and prompts to stdout.
# Returns:
#   Exit status of the last apt-get/read command run.
#######################################
function __install_package {
    local package_name="${1}"

    if dpkg -L "${package_name}" >/dev/null 2>&1; then
        echo "You have already installed ${package_name}."
    else
        if __confirm "Install ${package_name}? [y/N]: "; then
            # Keep apt-get from consuming package lists that the caller may read.
            sudo apt-get update </dev/null
            sudo apt-get install "${package_name}" -y </dev/null
        fi
    fi
    echo
}
