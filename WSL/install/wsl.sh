#!/bin/zsh

# Stop running this script if any error occurs
set -e

script_dir="${${(%):-%N}:A:h}"
repo_wsl_conf="${script_dir}/../wsl.conf"

source "${script_dir}/utils.sh"

__install_repo_path "${repo_wsl_conf}" /etc/wsl.conf '/etc/wsl.conf' link

echo 'WSL system configuration complete.'
echo 'Restart WSL from Windows with: wsl.exe --shutdown'
