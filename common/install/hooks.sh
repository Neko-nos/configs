#!/usr/bin/env zsh

set -euo pipefail

#######################################
# Build and install the turn-diff syntax highlighter binary.
# Globals:
#   HOME
#   XDG_CACHE_HOME
#   XDG_DATA_HOME
# Arguments:
#   None
# Outputs:
#   Writes Cargo build and installation output to stdout and stderr.
# Returns:
#   0 if the highlighter is built and installed, non-zero otherwise.
#######################################
function __install_turn_diff_highlighter() {
    local install_dir="${${(%):-%x}:A:h}"
    local manifest_path="${install_dir}/../hooks/turn-diff/syntect_highlight/Cargo.toml"
    local cache_dir="${XDG_CACHE_HOME:-${HOME}/.cache}/turn-diff"
    local bin_dir="${XDG_DATA_HOME:-${HOME}/.local/share}/turn-diff/bin"

    source "${install_dir}/rust.sh"

    cargo build --release --locked \
        --manifest-path "${manifest_path}" \
        --target-dir "${cache_dir}/target"
    mkdir -p "${bin_dir}"
    install -m 755 "${cache_dir}/target/release/syntect-highlight" \
        "${bin_dir}/syntect-highlight"
}

__install_turn_diff_highlighter
unset -f __install_turn_diff_highlighter
