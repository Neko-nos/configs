# shellcheck shell=bash

# Some tools source .bashrc from non-interactive shells; avoid changing their
# shell or configuring interactive behavior.
case $- in
    *i*) ;;
    *) return 0 ;;
esac

if [[ ":${PATH}:" != *":${HOME}/.local/bin:"* ]]; then
    export PATH="${HOME}/.local/bin:${PATH}"
fi

# VS Code opens interactive non-login shells, so select zsh here rather than in
# .bash_profile, which is read only by login shells.
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
eval "$(uv generate-shell-completion bash)"
eval "$(uvx --generate-shell-completion bash)"

git_completion_path="${HOME}/git-completion.bash"
if [[ ! -f "${git_completion_path}" ]]; then
    wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -O "${git_completion_path}"
fi
# shellcheck source=/dev/null
source "${git_completion_path}"

unset -v git_completion_path

script_dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
# shellcheck source=/dev/null
source "${script_dir}/aliases.sh"
# shellcheck source=/dev/null
source "${script_dir}/functions.sh"
# shellcheck source=/dev/null
source "${script_dir}/prompt.sh"
unset -v script_dir
