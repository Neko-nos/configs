#!/bin/bash

set -euo pipefail

#######################################
# Install Server command-line packages in an isolated Spack environment.
# Globals:
#   HOME
# Arguments:
#   None
# Outputs:
#   Writes Git and Spack installation output to stdout and stderr.
# Returns:
#   0 if Spack and all packages are installed, non-zero otherwise.
#######################################
function main() {
    local environment_dir="${HOME}/spack/var/spack/environments/server"
    local script_dir
    local spack_root="${HOME}/spack"

    script_dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

    # ref: https://github.com/spack/spack#installation
    if [[ ! -x "${spack_root}/bin/spack" ]]; then
        git clone --depth 2 --branch releases/latest https://github.com/spack/spack.git "${spack_root}"
    fi

    if [[ ! -d "${environment_dir}" ]]; then
        "${spack_root}/bin/spack" env track --name server "${script_dir}/.."
    fi

    # fzf supports external detection and the environment view is on PATH, so
    # exclude it to keep the requested root managed by this environment.
    "${spack_root}/bin/spack" external find --all --exclude fzf
    "${spack_root}/bin/spack" -e server install

    echo "Finished Spack package installation!"
}

main
