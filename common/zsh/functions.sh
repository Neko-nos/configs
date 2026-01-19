# cdr customization
if [[ -n $(echo ${^fpath}/chpwd_recent_dirs(N)) && -n $(echo ${^fpath}/cdr(N)) ]]; then
    autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
    add-zsh-hook chpwd chpwd_recent_dirs
    zstyle ':completion:*' recent-dirs-insert both
    zstyle ':chpwd:*' recent-dirs-default true
    zstyle ':chpwd:*' recent-dirs-max 1000
    zstyle ':chpwd:*' recent-dirs-file "$HOME/.cache/chpwd-recent-dirs"
fi

# Handle with environment variables so that it can be switched durinig shell session
function search-history() {
    BUFFER=$(\history -n -r 1 | awk '!a[$0]++' | $FILTER_CMD --query "$LBUFFER")
    CURSOR=$#BUFFER
    zle clear-screen
}
zle -N search-history
bindkey '^r' search-history

function search-cdr () {
    local selected_dir="$(cdr -l | sed 's/^[0-9]\+ \+//' | awk '!a[$0]++' | $FILTER_CMD --prompt="cdr >" --query "$LBUFFER")"
    if [[ -n "$selected_dir" ]]; then
        BUFFER="cd ${selected_dir}"
        zle accept-line
    fi
}
zle -N search-cdr
bindkey '^p' search-cdr
