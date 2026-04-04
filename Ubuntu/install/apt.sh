#!/bin/zsh

# Stop running this script if any error occurs
set -e

#######################################
# Read a yes/no confirmation from stdin.
# Globals:
#   None
# Arguments:
#   1: Prompt message
# Outputs:
#   Writes the prompt and a trailing newline to stdout.
# Returns:
#   0 if the user answers yes, 1 otherwise.
#######################################
function __confirm() {
    local prompt="${1}"

    printf '%s' "${prompt}"
    if read -q; then
        # Print a newline using echo because read -q doesn't.
        echo
        return 0
    fi

    echo
    return 1
}

# Update apt
# In a shell script, it's recommended to use apt-get instead of apt
# Using apt may result in the following warning:
# WARNING: apt does not have a stable CLI interface. Use with caution in scripts.
# ref: https://manpages.ubuntu.com/manpages/noble/man8/apt.8.html
sudo apt-get update
if __confirm "Upgrade all packages? [y/N]: "; then
    sudo apt-get upgrade -y
else
    echo "Skipping package upgrade."
fi
echo

# Now, install the tools that can be installed via apt
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
            # Keep apt-get from consuming the package list that the outer loop reads.
            sudo apt-get update </dev/null
            sudo apt-get install "${package_name}" -y </dev/null
        fi
    fi
    echo
}

# Install the packages listed in apt_packages.txt
package_dir="${${(%):-%N}:A:h}"
# Read package names from a dedicated file descriptor so apt-get cannot consume
# the package list after the user answers one of the prompts.
exec 3< "${package_dir}/apt_packages.txt"
while IFS= read -r line <&3
do
    [[ -z "${line}" || "${line}" == \#* ]] && continue
    __install_package "${line}"
done
exec 3<&-

echo 'Apt configuration complete!'
echo ''
