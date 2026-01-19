# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# zplug
source ~/.zplug/init.zsh
zplug "zsh-users/zsh-syntax-highlighting"
zplug romkatv/powerlevel10k, as:theme, depth:1
zplug "zsh-users/zsh-autosuggestions"
zplug "zsh-users/zsh-completions"
# Install plugins if there are plugins that have not been installed
if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi
# Then, source plugins and add commands to $PATH
zplug load --verbose

# ref: https://github.com/shunk031/dotfiles/blob/master/home/dot_zshrc#L6
typeset -gU path fpath

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
setopt hist_ignore_all_dups # Remove older duplicates
setopt hist_ignore_dups     # Do not add if same as previous command
setopt share_history        # Share command history data
setopt append_history       # Append to .zsh_history, don't overwrite it
setopt inc_append_history   # Add new history lines incrementally
setopt hist_no_store        # Do not store history command in history
setopt hist_reduce_blanks   # Remove extra blanks in history

# Helper functions
function info () {
    echo "Info:" "$*"
}

function warn () {
    echo "\033[33mWarning:\033[m" "$*"
}

function __load_zsh_files () {
    # Use indirect parameter expansion to avoid bad substitution error
    local os_specific_zsh_var="CONFIGS_${OSTYPE//[^a-zA-Z0-9]/_}_ZSH"
    if [[ -z "${CONFIGS_COMMON_ZSH}" ]]; then
        warn "CONFIGS_COMMON_ZSH should be set in .zprofile. Since it is not set, skipping loading zsh configuration files."
    fi
    if [[ -z ${os_specific_zsh_var} ]]; then
        info "No OS-specific zsh config files to load. If you have OS-specific zsh config files, please set the variable ${os_specific_zsh_var} in .zprofile."
    fi
    # Load aliases first to use them in functions if needed (e.g., GNU commands for MacOS)
    [[ -f "${CONFIGS_COMMON_ZSH}/aliases.sh" ]] && source "${CONFIGS_COMMON_ZSH}/aliases.sh"
    [[ -f "${(P)os_specific_zsh_var}/extra_aliases.sh" ]] && source "${(P)os_specific_zsh_var}/extra_aliases.sh"
    [[ -f "${CONFIGS_COMMON_ZSH}/functions.sh" ]] && source "${CONFIGS_COMMON_ZSH}/functions.sh"
    [[ -f "${(P)os_specific_zsh_var}/extra_functions.sh" ]] && source "${(P)os_specific_zsh_var}/extra_functions.sh"
}
__load_zsh_files

# cleanup helper variables and functions
unset -f info
unset -f warn
unset -f __load_zsh_files

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
