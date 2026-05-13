autoload -Uz __warn

# cdr customization
if [[ -n $(echo ${^fpath}/chpwd_recent_dirs(N)) && -n $(echo ${^fpath}/cdr(N)) ]]; then
    autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
    add-zsh-hook chpwd chpwd_recent_dirs
    zstyle ':completion:*' recent-dirs-insert both
    zstyle ':chpwd:*' recent-dirs-default true
    zstyle ':chpwd:*' recent-dirs-max 1000
    zstyle ':chpwd:*' recent-dirs-file "$HOME/.cache/chpwd-recent-dirs"
fi

# Handle with environment variables so that it can be switched during shell session
typeset -g _cdr_search_warned_unsupported=0

#######################################
# Emit a warning once per session for cdr search.
# Globals:
#   _cdr_search_warned_unsupported
# Arguments:
#   1: Warning message
# Outputs:
#   Writes warning to stderr
# Returns:
#   0 always
#######################################
function _search_cdr_warn_once() {
    emulate -L zsh
    local message="${1}"
    if (( _cdr_search_warned_unsupported != 0 )); then
        return 0
    fi
    _cdr_search_warned_unsupported=1
    if typeset -f __warn >/dev/null 2>&1; then
        __warn "${message}"
    else
        echo "Warning: ${message}" >&2
    fi
}

#######################################
# Search recent directories and populate the command line with a cd command.
# Globals:
#   FILTER_CMD
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   0 on success, non-zero on failure.
#######################################
function search-cdr () {
    emulate -L zsh
    local -a filter_cmd
    if [[ -n "${FILTER_CMD:-}" ]]; then
        filter_cmd=(${(z)FILTER_CMD})
    elif command -v fzf >/dev/null 2>&1; then
        filter_cmd=(fzf)
    else
        _search_cdr_warn_once "FILTER_CMD is not set and fzf is unavailable."
        return 0
    fi
    local selected_dir="$(cdr -l | sed 's/^[0-9]\+ \+//' | awk '!a[$0]++' | "${filter_cmd[@]}" --prompt="cdr >" --query "$LBUFFER")"
    if [[ -n "${selected_dir}" ]]; then
        BUFFER="cd ${(q)selected_dir}"
        zle accept-line
    fi
}
zle -N search-cdr
bindkey '^p' search-cdr

# Handle with environment variables so that it can be switched during shell session
typeset -g _history_search_warned_unsupported=0

#######################################
# Emit a warning once per session for history search.
# Globals:
#   _history_search_warned_unsupported
# Arguments:
#   1: Warning message
# Outputs:
#   Writes warning to stderr
# Returns:
#   0 always
#######################################
function _history_search_warn_once() {
    emulate -L zsh
    local message="${1}"
    if (( _history_search_warned_unsupported != 0 )); then
        return 0
    fi
    _history_search_warned_unsupported=1
    if typeset -f __warn >/dev/null 2>&1; then
        __warn "${message}"
    else
        echo "Warning: ${message}" >&2
    fi
}

#######################################
# Emit history entries as NUL-delimited records, preserving multiline commands.
# Globals:
#   HISTFILE
# Arguments:
#   None
# Outputs:
#   Writes NUL-delimited entries to stdout
# Returns:
#   0 on success, non-zero on failure.
#######################################
function _history_entries_nul() {
    emulate -L zsh
    local histfile="${HISTFILE:-$HOME/.zsh_history}"
    if [[ -z "${histfile}" || ! -f "${histfile}" ]]; then
        return 1
    fi

    zmodload zsh/parameter || return 1
    local histsize="${HISTSIZE:-10000}"
    fc -p -a "${histfile}" "${histsize}" 0 || return 1

    local -A seen
    local -a event_numbers
    event_numbers=("${(@kon)history}")
    local i
    for (( i=${#event_numbers[@]}; i>=1; i-- )); do
        local entry="${history[${event_numbers[i]}]}"
        if (( ! ${+seen[${entry}]} )); then
            seen[${entry}]=1
            print -rn -- "${entry}"$'\0'
        fi
    done
}

#######################################
# Search history entries using an external filter.
# Globals:
#   FILTER_CMD
#   HISTFILE
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   0 on success, non-zero on failure.
#######################################
function search-history() {
    emulate -L zsh
    local -a filter_cmd
    if [[ -n "${FILTER_CMD:-}" ]]; then
        filter_cmd=(${(z)FILTER_CMD})
    elif command -v fzf >/dev/null 2>&1; then
        filter_cmd=(fzf)
    else
        _history_search_warn_once "FILTER_CMD is not set and fzf is unavailable."
        return 0
    fi

    local cmd_name="${filter_cmd[1]}"
    local supports_nul=0
    case "$cmd_name" in
        fzf|fzf-tmux|sk|skim)
            supports_nul=1
            ;;
        *)
            supports_nul=0
            ;;
    esac

    if (( supports_nul == 0 )); then
        _history_search_warn_once "FILTER_CMD must support NUL-delimited input to preserve multiline history."
        return 0
    fi

    # Use NUL-delimited input instead of newline-delimited input to handle multiline commands correctly.
    local selection="$(_history_entries_nul | "${filter_cmd[@]}" --read0 --query "${LBUFFER}")"
    if [[ -n "${selection}" ]]; then
        selection="${selection%$'\n'}"
        BUFFER="${selection}"
        CURSOR=${#BUFFER}
    fi
    zle clear-screen
}
zle -N search-history
bindkey '^r' search-history

# ref: https://qiita.com/momo-lab/items/523fc83fbfa39fa5fd60
function replace_multiple_dots() {
    local dots=$LBUFFER[-2,-1]
    if [[ $dots == ".." ]]; then
        LBUFFER=$LBUFFER[1,-3]'../.'
    fi
    zle self-insert
}
zle -N replace_multiple_dots
bindkey "." replace_multiple_dots
