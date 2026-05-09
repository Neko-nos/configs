#!/bin/zsh

# Stop running this script if any error occurs
set -e

script_dir="${${(%):-%N}:A:h}"

source "${script_dir}/utils.sh"

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

# Read package names from a dedicated file descriptor so apt-get cannot consume
# the package list after the user answers one of the prompts.
exec 3< "${script_dir}/apt_packages.txt"
while IFS= read -r line <&3
do
    [[ -z "${line}" || "${line}" == \#* ]] && continue
    __install_package "${line}"
done
exec 3<&-

echo 'Apt configuration complete!'
echo ''
