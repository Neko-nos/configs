autoload -Uz __safe_alias __warn __update_cache

typeset -ga SAFE_ALIAS_MANAGER_CMD SAFE_ALIAS_UPDATE_CMD
# Use arrays for commands to avoid word-splitting and quoting pitfalls.
if [[ "${OSTYPE}" == "darwin"* ]]; then
    SAFE_ALIAS_MANAGER_CMD=(brew)
    SAFE_ALIAS_UPDATE_CMD=()
else
    SAFE_ALIAS_MANAGER_CMD=(sudo apt-get)
    SAFE_ALIAS_UPDATE_CMD=(sudo apt-get update)
fi

# ref: https://atmarkit.itmedia.co.jp/ait/articles/1606/28/news021.html
__safe_alias ls 'ls -AX --color=auto'

# Custom colors for ls and completion
function __load_ls_color_cache() {
    local ls_color_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zshrc/ls_color_cache.zsh"
    local dircolors_file="${HOME}/.dircolors-solarized/dircolors.ansi-light"
    __update_cache "dircolors" "${ls_color_cache}" "${dircolors_file}" -- "${dircolors_file}" || true
    source "${ls_color_cache}"
}
__load_ls_color_cache
unset -f __load_ls_color_cache

if [[ -n "$LS_COLORS" ]]; then
    zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
fi

# ref: https://atmarkit.itmedia.co.jp/ait/articles/1802/01/news025.html
__safe_alias tree 'tree -acq -I ".git|.ruff_cache|.venv|env|venv|__pycache__|.DS_Store"'

# Avoid recursive function call by using a different name than tree
alias ctree='_custom_tree'
# ref: https://qiita.com/osw_nuco/items/a5d7173c1e443030875f
function _custom_tree() {
    # Limit output when running tree alias in home directory to avoid excessive files
    if [[ "${PWD}" == "${HOME}" ]]; then
        tree -L 2 "$@"
    else
        tree "$@"
    fi
}

__safe_alias diff 'colordiff -u'
__safe_alias icdiff 'icdiff -U 1 --line-numbers'

# Clean up helper functions and variables.
# `__warn` and `__update_cache` are shared helpers that remain available until
# `.zshrc` finishes loading, so cleanup is centralized there.
unset -f __safe_alias
unset -v SAFE_ALIAS_MANAGER_CMD SAFE_ALIAS_UPDATE_CMD
