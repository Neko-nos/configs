# shellcheck shell=bash

export PATH="${HOME}/.local/bin:${PATH}"

# Bash reads .bash_profile for login shells and .bashrc for interactive
# non-login shells. Source .bashrc here so SSH login shells get the same setup.
if [[ -f "${HOME}/.bashrc" ]]; then
    # shellcheck source=/dev/null
    source "${HOME}/.bashrc"
fi
