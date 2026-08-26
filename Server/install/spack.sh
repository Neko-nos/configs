#!/bin/bash

set -euo pipefail

#######################################
# Install Server command-line packages in an isolated Spack environment.
# Globals:
#   HOME
#   SPACK_DISABLE_LOCAL_CONFIG
# Arguments:
#   None
# Outputs:
#   Writes Git and Spack installation output to stdout and stderr.
# Returns:
#   0 if Spack and all packages are installed, non-zero otherwise.
#######################################
function main() {
    local architecture
    local environment_dir
    local -a external_find_args
    local script_dir
    local spack_root="${HOME}/spack"

    script_dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

    # ref: https://github.com/spack/spack#installation
    if [[ ! -x "${spack_root}/bin/spack" ]]; then
        git clone --depth 2 --branch releases/latest https://github.com/spack/spack.git "${spack_root}"
    fi

    architecture="$("${spack_root}/bin/spack" arch)"
    environment_dir="${spack_root}/var/spack/environments/${architecture}/server"

    # A shared home can span incompatible operating systems and CPUs, so each
    # architecture needs its own concretization, view, and detected externals.
    export SPACK_DISABLE_LOCAL_CONFIG=true
    if [[ ! -d "${environment_dir}" ]]; then
        "${spack_root}/bin/spack" env create --dir "${environment_dir}" \
            "${script_dir}/../spack.yaml"
    fi

    external_find_args=(
        # Keep this root managed instead of detecting its view.
        --exclude fzf
        # Its detector does not check development files.
        --exclude openssl
        # Search host paths, not another architecture's view.
        --path /usr
        --path /usr/local
    )
    "${spack_root}/bin/spack" -D "${environment_dir}" external find \
        "${external_find_args[@]}"
    "${spack_root}/bin/spack" -D "${environment_dir}" install

    printf "Finished Spack package installation for %s!\n" "${architecture}"
}

main
