#!/usr/bin/env zsh

set -euo pipefail

#######################################
# Format zsh source files.
# Arguments:
#   Paths to .zsh, .zshrc, or .sh files.
# Outputs:
#   Writes shfmt diagnostics to stderr.
# Returns:
#   The shfmt exit status, or 0 when no zsh files match.
#######################################
function main() {
    local script
    local first_line
    local -a zsh_files=()

    for script in "$@"; do
        # This repository's sourced .sh files default to zsh.
        if [[ "$script" == *.sh ]]; then
            first_line="$(head -n 1 "$script")"
            if [[ "$first_line" == '#!'* && "$first_line" != *zsh* ]] ||
                # shellcheck does not support zsh
                grep -Eq '^[[:space:]]*#[[:space:]]*shellcheck[[:space:]]+shell=bash([[:space:]]|$)' "$script"; then
                continue
            fi
        fi
        zsh_files+=("$script")
    done

    if ((${#zsh_files[@]})); then
        shfmt -w -ln=zsh -i 4 -ci "${zsh_files[@]}"
    fi
}

main "$@"
