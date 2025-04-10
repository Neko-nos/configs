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
    echo
    sudo apt-get upgrade -y
else
    echo "Skipping package upgrade."
fi
echo

# Now, install the tools that can be installed via apt
# define a common function to install a package
function install_package {
    if [[ "$(dpkg -L "${1}")" ]]; then
        echo "You have already installed ${1}."
    else
        printf "Install ${1}? [y/N]: "
        if read -q; then
            echo
            sudo apt-get update
            sudo apt-get install ${1} -y
        fi
    fi
    echo
}

# Install the packages listed in apt_packages.txt
cd "${1}"
while read line
do
    install_package "${line}"
done < 'apt_packages.txt'

echo 'Apt configuration complete!'
echo ''
