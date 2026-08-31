# shellcheck shell=bash

# VS Code opens interactive non-login shells, so select zsh here rather than in
# .bash_profile, which is read only by login shells.
if [[ $- == *i* ]]; then
    slurm_managed=false
    for slurm_command in sbatch scontrol sinfo squeue srun; do
        if command -v "${slurm_command}" >/dev/null 2>&1; then
            slurm_managed=true
            break
        fi
    done

    if [[ "${slurm_managed}" == false ]] && command -v zsh >/dev/null 2>&1; then
        SHELL="$(command -v zsh)"
        export SHELL
        exec "${SHELL}" -l
    fi

    unset -v slurm_managed slurm_command
fi

script_dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
# shellcheck source=/dev/null
source "${script_dir}/utils.sh"

# Spack
function __load_spack() {
    local spack_root="${HOME}/spack"
    if [[ ! -r "${spack_root}/share/spack/setup-env.sh" ]]; then
        return
    fi
    # shellcheck source=/dev/null
    source "${spack_root}/share/spack/setup-env.sh"
    # setup-env.sh defines spack as a function, so `hash spack` does not record
    # the executable path needed to detect cache invalidation.
    hash -p "${spack_root}/bin/spack" spack

    local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/spack"
    local architecture_cache="${cache_dir}/architecture-${HOSTNAME}"
    __update_cache "spack" "${architecture_cache}" -- arch || return

    local architecture
    architecture="$(<"${architecture_cache}")"
    local environment_dir="${spack_root}/var/spack/environments/${architecture}/server"
    local activation_cache="${cache_dir}/server-${HOSTNAME}.bash"
    __update_cache "spack" "${activation_cache}" \
        "${environment_dir}/spack.yaml" \
        "${environment_dir}/spack.lock" \
        "${environment_dir}/.spack-env/view/.spack-view" \
        -- env activate --sh "${environment_dir}" || return
    # shellcheck source=/dev/null
    source "${activation_cache}"
}
__load_spack
unset -f __load_spack

# Some tools source .bashrc from non-interactive shells; load Spack for them,
# but avoid changing their shell or configuring interactive behavior.
case $- in
    *i*) ;;
    *) return 0 ;;
esac

if [[ ":${PATH}:" != *":${HOME}/.local/bin:"* ]]; then
    export PATH="${HOME}/.local/bin:${PATH}"
fi

# Match the zsh setup's no_beep and case-insensitive completion behavior.
set -o emacs
bind 'set bell-style none'
bind 'set completion-ignore-case on'
bind 'set show-all-if-ambiguous on'
bind '"\e[1;5C": forward-word'
bind '"\e[1;5D": backward-word'
# ref: https://stackoverflow.com/questions/10980575/how-can-i-unbind-and-remap-c-w-in-bash
if [[ -t 0 ]]; then
    stty werase undef
fi
bind -m emacs-standard '"\C-w": unix-filename-rubout'

# Keep Bash behavior close to zsh's glob, script, and history options where
# Bash has a direct equivalent.
shopt -s dotglob
shopt -s extglob
shopt -s globstar
shopt -s interactive_comments
shopt -s cmdhist
shopt -s histappend
shopt -s lithist

HISTFILE="${HOME}/.bash_history"
HISTSIZE=10000
HISTFILESIZE=10000
HISTCONTROL="ignoreboth:erasedups"
HISTIGNORE="cd:cd *:pushd:pushd *:popd:popd *:mkdir:mkdir *:pwd:exit:clear:man:man *:history:history *:kill:kill *"

# Append and incrementally load history at each prompt so separate SSH sessions
# can see each other's recent commands without rereading the complete file.
PROMPT_COMMAND="history -a; history -n; _record_cdr"

# Completions
function __load_completion_cache() {
    local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/bashrc"

    # uv
    # ref: https://docs.astral.sh/uv/getting-started/installation/
    local uv_cache="${cache_dir}/uv-completion.bash"
    if __update_cache "uv" "${uv_cache}" -- generate-shell-completion bash; then
        # shellcheck source=/dev/null
        source "${uv_cache}"
    fi

    local uvx_cache="${cache_dir}/uvx-completion.bash"
    if __update_cache "uvx" "${uvx_cache}" -- --generate-shell-completion bash; then
        # shellcheck source=/dev/null
        source "${uvx_cache}"
    fi
}
__load_completion_cache
unset -f __load_completion_cache
unset -f __update_cache
unset -f __warn

git_completion_path="${HOME}/git-completion.bash"
if [[ ! -f "${git_completion_path}" ]]; then
    wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -O "${git_completion_path}"
fi
# shellcheck source=/dev/null
source "${git_completion_path}"

unset -v git_completion_path

# shellcheck source=/dev/null
source "${script_dir}/aliases.sh"
# shellcheck source=/dev/null
source "${script_dir}/functions.sh"
# shellcheck source=/dev/null
source "${script_dir}/prompt.sh"
unset -v script_dir
