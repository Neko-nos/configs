#!/bin/bash

set -euo pipefail

script_dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${script_dir}/utils.sh"

__install_symlink "${script_dir}/../bash/.bash_profile" "${HOME}/.bash_profile" ".bash_profile"
__install_symlink "${script_dir}/../bash/.bashrc" "${HOME}/.bashrc" ".bashrc"

echo "Finished bash configuration!"
