# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Sheldon
eval "$(sheldon source)"

# Shared function autoload path
typeset -g _common_functions_dir="${${(%):-%N}:A:h}/functions"
if [[ -d "${_common_functions_dir}" ]]; then
    fpath=("${_common_functions_dir}" "${fpath[@]}")
fi
unset -v _common_functions_dir

# ref: https://github.com/shunk031/dotfiles/blob/master/home/dot_zshrc#L6
typeset -gU path fpath

# General settings
setopt extended_glob

# Completion
autoload -Uz compinit && compinit
# Match both lowercase and uppercase letters during completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*:default' menu select=1
setopt autoremoveslash
setopt no_beep
# Correct typos
setopt correct
setopt correct_all

# Fix Ctrl+Left/Right not working in some terminals
# 参考: https://unix.stackexchange.com/questions/58870/ctrl-left-right-arrow-keys-issue
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

# uv
# ref: https://docs.astral.sh/uv/getting-started/installation/
if command -v uv >/dev/null 2>&1; then
    eval "$(uv generate-shell-completion zsh)"
    eval "$(uvx --generate-shell-completion zsh)"
fi
# Additional configuration required for zsh
# ref: https://github.com/astral-sh/uv/issues/8432#issuecomment-2965692994
function _uv_run_mod() {
    # Filter out options
    if [[ "$words[2]" == "run" && "$words[CURRENT]" != -* ]]; then
        # Limit to .py files
        _arguments '*:filename:_files -g "*.py"'
    else
        _uv "$@"
    fi
}
compdef _uv_run_mod uv

# History settings
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
HISTORY_IGNORE="(cd|mkdir|pwd|exit|clear|man|history)(| *)"
# Avoid duplicate entries in history
setopt hist_ignore_all_dups
setopt hist_ignore_dups
setopt hist_save_no_dups
setopt hist_no_store
# Remove extra blanks in history entries
setopt hist_reduce_blanks
# Share history between all sessions
setopt share_history
setopt append_history
# Write to the history file immediately, not when the shell exits
setopt inc_append_history
setopt extended_history
setopt hist_fcntl_lock

# Helper functions
autoload -Uz __warn __info

function __load_zsh_files () {
    emulate -L zsh
    # Use indirect parameter expansion to avoid bad substitution error
    local os_specific_zsh_var="CONFIGS_${OSTYPE//[^a-zA-Z0-9]/_}_ZSH"
    if [[ -z "${CONFIGS_COMMON_ZSH}" ]]; then
        __warn "CONFIGS_COMMON_ZSH should be set in .zprofile. Since it is not set, skipping loading zsh configuration files."
        return 0
    fi
    if [[ -z ${os_specific_zsh_var} ]]; then
        __info "No OS-specific zsh config files to load. If you have OS-specific zsh config files, please set the variable ${os_specific_zsh_var} in .zprofile."
        local use_os_specific_zsh_var=false
    else
        local use_os_specific_zsh_var=true
    fi
    # Load aliases first to use them in other files if needed (e.g., GNU commands for MacOS)
    [[ -f "${CONFIGS_COMMON_ZSH}/aliases.sh" ]] && source "${CONFIGS_COMMON_ZSH}/aliases.sh"
    if $use_os_specific_zsh_var; then
        [[ -f "${(P)os_specific_zsh_var}/extra_aliases.sh" ]] && source "${(P)os_specific_zsh_var}/extra_aliases.sh"
    fi
    [[ -f "${CONFIGS_COMMON_ZSH}/functions.sh" ]] && source "${CONFIGS_COMMON_ZSH}/functions.sh"
    if $use_os_specific_zsh_var; then
        [[ -f "${(P)os_specific_zsh_var}/extra_functions.sh" ]] && source "${(P)os_specific_zsh_var}/extra_functions.sh"
    fi
    [[ -f "${CONFIGS_COMMON_ZSH}/history.sh" ]] && source "${CONFIGS_COMMON_ZSH}/history.sh"
}
__load_zsh_files

# cleanup helper variables and functions
unset -f __warn
unset -f __info
unset -f __load_zsh_files

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
