function __safe_alias() {
    if command -v "$2" >/dev/null 2>&1; then
        alias "$1"="$2"
    else
        local target_package=${3:-$2}
        printf "Install $target_package? [y/N]: "
        if read -q; then
            echo; brew install "$target_package"
            alias "$1"="$2"
        fi
    fi
}

__safe_alias grep 'ggrep' 'grep'
__safe_alias sed 'gsed' 'gnu-sed'
