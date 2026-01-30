#!/bin/zsh

# Stop running this script if any error occurs
set -e

# Update apt
# In a shell script, it's recommended to use apt-get instead of apt
# Using apt may result in the following warning:
# WARNING: apt does not have a stable CLI interface. Use with caution in scripts.
# ref: https://manpages.ubuntu.com/manpages/noble/man8/apt.8.html
sudo apt-get update
printf "Upgrade all packages? [y/N]: "
if read -q; then
    # Print a newline using echo because read -q doesn't.
    echo
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
    if [[ "$(dpkg -L "${1}")" ]]; then
        echo "You have already installed ${1}."
    else
        printf "Install ${1}? [y/N]: "
        if read -q; then
            # Print a newline using echo because read -q doesn't.
            echo
            sudo apt-get update
            sudo apt-get install ${1} -y
        fi
    fi
    echo
}

# Install the packages listed in apt_packages.txt
while read -r line
do
    __install_package "${line}"
done < "${${(%):-%N}:A:h}/apt_packages.txt"

echo 'Apt configuration complete!'
echo ''
