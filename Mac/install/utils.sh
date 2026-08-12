#!/usr/bin/env zsh

# Top-level `set -euo pipefail` would not apply when these functions run later
# and could change the caller's options if this file is sourced directly.
# Each function instead combines `emulate -L zsh` with `ERR_RETURN` to localize
# option changes and stop on command failure without exiting the caller's shell.

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
#   Optional application bundle path for detecting a cask installed outside Homebrew.
# Outputs:
#   Writes status messages and prompts to stdout.
# Returns:
#   Exit status of the last brew/read command run.
#######################################
function __install_formula {
    emulate -L zsh
    setopt err_return
    local formula_name="${1}"
    local application_path="${2:-}"

    # `command -v` would incorrectly match macOS-provided commands like `grep`,
    # so check Homebrew metadata before considering an explicitly supplied app bundle.
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
    # some software like vscode offers download via their official webpages.
    elif [[ -n "${application_path}" && -d "${application_path}" ]]; then
        echo "You have already installed ${formula_name}."
    else
        if __confirm "Install ${formula_name}? [y/N]: "; then
            # Keep brew from consuming the formula list that the outer loop reads.
            brew install "${formula_name}" </dev/null
        fi
    fi
    echo
}

#######################################
# Add an application to the current user's macOS login items.
# Globals:
#   None
# Arguments:
#   Application name as shown in System Settings
#   Absolute path to the application bundle
# Outputs:
#   Writes a status message to stdout.
# Returns:
#   0 if the application is absent, already configured, or added successfully
#   Non-zero if macOS cannot update the login items
#######################################
function __enable_login_item {
    emulate -L zsh
    setopt err_return
    local application_name="${1}"
    local application_path="${2}"
    local login_item_script="${${(%):-%x}:A:h}/enable_login_item.applescript"

    [[ -d "${application_path}" ]] || return 0

    osascript "${login_item_script}" "${application_name}" "${application_path}" >/dev/null

    echo "Enabled ${application_name} at login."
}

#######################################
# Open an installed application so macOS can present its setup and permission UI.
# Globals:
#   None
# Arguments:
#   Application name as shown to the user
#   Absolute path to the application bundle
# Outputs:
#   Writes a permission reminder to stdout.
# Returns:
#   0 if the application is absent or opened successfully
#   Non-zero if macOS cannot open the application
#######################################
function __open_application_for_setup {
    emulate -L zsh
    setopt err_return
    local application_name="${1}"
    local application_path="${2}"

    [[ -d "${application_path}" ]] || return 0

    open "${application_path}"
    echo "Opened ${application_name}; approve the macOS permission prompts it displays."
}
