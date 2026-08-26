#!/bin/bash

set -euo pipefail

script_dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
repo_root="$(readlink -f "${script_dir}/../..")"

# shellcheck source=/dev/null
source "${script_dir}/utils.sh"

__install_repo_path "${script_dir}/../bash/.bash_profile" "${HOME}/.bash_profile" ".bash_profile" copy
__install_repo_path "${script_dir}/../bash/.bashrc" "${HOME}/.bashrc" ".bashrc" link
zsh "${repo_root}/common/install/zsh.sh" Server

echo "Finished zsh configuration!"
