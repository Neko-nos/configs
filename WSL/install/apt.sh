#!/bin/zsh

# Stop running this script if any error occurs
set -e

# Update apt
# In a shell script, it's recommended to use apt-get instead of apt
# Using apt may result in the following warning:
# WARNING: apt does not have a stable CLI interface. Use with caution in scripts.
# ref: https://manpages.ubuntu.com/manpages/noble/man8/apt.8.html
sudo apt-get update
sudo apt-get upgrade -y

echo ''

# Now, install the tools that can be installed via apt
# define a common function to install a package
function install_package {
    if [[ "$(dpkg -L "${1}")" ]]; then
        # `sudo apt-get upgrade -y` have already updated all of the installed packages
        # Therefore, there's no need to update packages individually
        echo "You have already installed ${1}."
    else
        printf "Install ${1}? [y/N]: "
        if read -q; then
            echo; sudo apt-get install ${1}
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
