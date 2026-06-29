#!/bin/bash

set -euo pipefail

script_dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

bash "${script_dir}/commands.sh"
bash "${script_dir}/build_cmds.sh"
bash "${script_dir}/bash.sh"
bash "${script_dir}/nano.sh"
bash "${script_dir}/codex.sh"

echo "Finished server configuration!"
