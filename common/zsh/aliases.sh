autoload -Uz __safe_alias

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
eval $(dircolors ~/.dircolors-solarized/dircolors.ansi-light)
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

# Clean up helper functions and variables
unset -f __safe_alias
unset -v SAFE_ALIAS_MANAGER_CMD SAFE_ALIAS_UPDATE_CMD
