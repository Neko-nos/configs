#!/bin/zsh

# Stop running this script if any error occurs
set -e

script_dir="${${(%):-%N}:A:h}"
common_install_dir="${script_dir}/../../common/install"
common_install_dir="${common_install_dir:A}"

# apt
source "${script_dir}/apt.sh"

# Zsh
source "${common_install_dir}/zsh.sh" Ubuntu

# Git
printf 'Do you also want to set up git configurations? [y/N]:'
if read -q; then
    # Print a newline using echo because read -q doesn't.
    echo
    source "${common_install_dir}/git.sh"
else
    echo
fi

# Python
printf 'Do you also want to set up Python configurations? [y/N]:'
if read -q; then
    # Print a newline using echo because read -q doesn't.
    echo
    source "${common_install_dir}/python.sh"
else
    echo
fi

echo 'All installation scripts have been executed successfully.'
echo 'For additional installation instructions, please refer to the configs/README.md file.'
