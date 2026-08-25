# shellcheck shell=bash

export PATH="${HOME}/spack/bin:${HOME}/.local/bin:${PATH}"
if command -v spack >/dev/null 2>&1 \
    && [[ -d "${HOME}/spack/var/spack/environments/$(spack arch)/server" ]]; then
    # Activation prints shell assignments that must run here to update PATH.
    eval "$(spack env activate --sh "${HOME}/spack/var/spack/environments/$(spack arch)/server")"
fi

# Bash reads .bash_profile for login shells and .bashrc for interactive
# non-login shells. Source .bashrc here so SSH login shells get the same setup.
if [[ -f "${HOME}/.bashrc" ]]; then
    # shellcheck source=/dev/null
    source "${HOME}/.bashrc"
fi

export HF_HOME='/data/umihebi0/users/yoshihira/.cache/huggingface/'
