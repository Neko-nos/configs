#!/bin/zsh

script_dir="${${(%):-%N}:A:h}"
common_install_dir="${script_dir}/../../common/install"
common_install_dir="${common_install_dir:A}"

source "${common_install_dir}/utils.sh"

#######################################
# Install or update a package via apt-get.
# Globals:
#   None
# Arguments:
#   Package name to check, install, or update.
# Outputs:
#   Writes status messages and prompts to stdout.
# Returns:
#   Exit status of the last apt-get/read command run.
#######################################
function __install_package {
    local package_name="${1}"

    if dpkg -L "${package_name}" >/dev/null 2>&1; then
        echo "You have already installed ${package_name}."
        if __confirm "Update ${package_name}? [y/N]: "; then
            # Keep apt-get from consuming package lists that the caller may read.
            sudo apt-get update </dev/null
            sudo apt-get install "${package_name}" -y </dev/null
        fi
    else
        if __confirm "Install ${package_name}? [y/N]: "; then
            # Keep apt-get from consuming package lists that the caller may read.
            sudo apt-get update </dev/null
            sudo apt-get install "${package_name}" -y </dev/null
        fi
    fi
    echo
}

#######################################
# Install or update a Windows package via WinGet.
# Globals:
#   None
# Arguments:
#   WinGet package identifier.
#   Package name to display.
# Outputs:
#   Writes status messages and prompts to stdout.
# Returns:
#   Exit status of the last winget.exe/read command run.
#######################################
function __install_winget_package {
    local package_id="${1}"
    local display_name="${2}"

    if winget.exe list "${package_id}" | grep -Fq -- "${package_id}"; then
        echo "You have already installed ${display_name}."
        if __confirm "Update ${display_name}? [y/N]: "; then
            winget.exe upgrade "${package_id}"
        fi
    elif __confirm "Install ${display_name}? [y/N]: "; then
        winget.exe install "${package_id}"
    fi
    echo
}
