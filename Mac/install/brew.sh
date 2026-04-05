#!/usr/bin/env zsh

# Stop running this script if any error occurs
set -e

#######################################
# Read a yes/no confirmation from the controlling terminal.
# Globals:
#   None
# Arguments:
#   1: Prompt message
# Outputs:
#   Writes the prompt and a trailing newline to stdout
# Returns:
#   0 if the user answers yes, 1 otherwise
#######################################
function __confirm() {
    local prompt="${1}"

    printf '%s' "${prompt}"
    if read -q; then
        # Print a newline using echo because read -q doesn't.
        echo
        return 0
    fi

    echo
    return 1
}

# Install Homebrew
# ref: https://brew.sh/
if command -v brew >/dev/null 2>&1; then
    echo "You have already installed Homebrew."
    if __confirm "Update brew? [y/N]: "; then
        brew update
    fi
    echo
else
    if __confirm "Install brew? [y/N]: "; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
fi

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

# Install the formulae required by brew_formulae.txt (default to the minimum formulae required to source our .zshrc)
script_dir="${${(%):-%N}:A:h}"
# Read package names from a dedicated file descriptor so interactive prompts can
# keep using the terminal stdin even after a brew command runs.
exec 3< "${script_dir}/brew_formulae.txt"
while IFS= read -r line <&3
do
    # We allow blank lines and comments (#) in brew_formulae.txt.
    [[ -z "${line}" || "${line}" == \#* ]] && continue
    __install_formula "${line}"
done
exec 3<&-

# PATH settings
coreutils_path='export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"'
if ! grep -F "${coreutils_path}" ~/.zprofile; then
    echo "${coreutils_path}" >> ~/.zprofile
fi

echo 'Finished Homebrew configuration!'
echo ''
