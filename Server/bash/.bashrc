# shellcheck shell=bash

# Some tools source .bashrc from non-interactive shells; keep this file for
# prompt, readline, aliases, functions, and history behavior only.
case $- in
    *i*) ;;
    *) return 0 ;;
esac

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

eval "$(uv generate-shell-completion bash)"
eval "$(uvx --generate-shell-completion bash)"

script_dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
# shellcheck source=/dev/null
source "${script_dir}/aliases.sh"
# shellcheck source=/dev/null
source "${script_dir}/functions.sh"
# shellcheck source=/dev/null
source "${script_dir}/prompt.sh"
unset -v script_dir
