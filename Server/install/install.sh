#!/bin/bash

set -euo pipefail

script_dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
repo_root="$(readlink -f "${script_dir}/../..")"
common_install_dir="${repo_root}/common/install"

# shellcheck source=/dev/null
source "${script_dir}/utils.sh"

server_shell="$(__select_server_shell)"
printf "Selected %s for this server.\n" "${server_shell}"

bash "${script_dir}/commands.sh" "${server_shell}"
bash "${script_dir}/build_cmds.sh"
bash "${script_dir}/${server_shell}.sh"

if __confirm "Do you also want to set up git configurations? [y/N]: "; then
    zsh "${common_install_dir}/git.sh"
fi

if __confirm "Do you also want to set up GitHub SSH authentication? [y/N]: "; then
    zsh "${common_install_dir}/github_ssh.sh"
fi

if __confirm "Do you also want to set up nano configurations? [y/N]: "; then
    bash "${script_dir}/nano.sh"
fi

if __confirm "Do you also want to set up Codex CLI and configurations? [y/N]: "; then
    bash "${script_dir}/codex.sh"
fi

echo "Finished server configuration!"
