autoload -Uz __safe_alias

typeset -ga SAFE_ALIAS_MANAGER_CMD SAFE_ALIAS_UPDATE_CMD
# Use arrays for commands to avoid word-splitting and quoting pitfalls.
SAFE_ALIAS_MANAGER_CMD=(brew)
SAFE_ALIAS_UPDATE_CMD=()

__safe_alias grep 'ggrep' 'grep'
__safe_alias sed 'gsed' 'gnu-sed'

# Clean up helper functions and variables
unset -f __safe_alias
unset -v SAFE_ALIAS_MANAGER_CMD SAFE_ALIAS_UPDATE_CMD
