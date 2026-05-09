#!/usr/bin/env zsh

script_dir="${${(%):-%N}:A:h}"
common_install_dir="${script_dir}/../../common/install"
common_install_dir="${common_install_dir:A}"

source "${common_install_dir}/utils.sh"

#######################################
# Install or upgrade a Homebrew formula based on its availability.
# Globals:
#   None
# Arguments:
#   Formula name to check, install, or upgrade.
# Outputs:
#   Writes status messages and prompts to stdout.
# Returns:
#   Exit status of the last brew/read command run.
#######################################
function __install_formula {
    local formula_name="${1}"

    # `command -v` would incorrectly match macOS-provided commands like `grep`,
    # so only use Homebrew metadata to decide whether this package is installed.
    if brew list --formula --versions "${formula_name}" >/dev/null 2>&1; then
        echo "You have already installed ${formula_name}."
        if __confirm "Update ${formula_name}? [y/N]: "; then
            # Keep brew from consuming the formula list that the outer loop reads.
            brew upgrade "${formula_name}" </dev/null
        fi
    elif brew list --cask --versions "${formula_name}" >/dev/null 2>&1; then
        echo "You have already installed ${formula_name}."
        if __confirm "Update ${formula_name}? [y/N]: "; then
            # Keep brew from consuming the formula list that the outer loop reads.
            brew upgrade --cask "${formula_name}" </dev/null
        fi
    else
        if __confirm "Install ${formula_name}? [y/N]: "; then
            # Keep brew from consuming the formula list that the outer loop reads.
            brew install "${formula_name}" </dev/null
        fi
    fi
    echo
}
