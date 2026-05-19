#######################################
# Load cached Homebrew shell environment.
# Globals:
#   XDG_CACHE_HOME
#   HOME
# Arguments:
#   None
#######################################
function __load_brew_shellenv_cache() {
    emulate -L zsh -o extended_glob

    local brew_cmd="/opt/homebrew/bin/brew"
    local cache_file="${XDG_CACHE_HOME:-${HOME}/.cache}/zprofile/brew-shellenv.zsh"
    if [[ ! -x "${brew_cmd}" ]]; then
        return 0
    fi

    if [[ ! -r "${cache_file}" || -n "${cache_file}"(#qN.mh+24) ]]; then
        mkdir -p "${cache_file:h}"
        "${brew_cmd}" shellenv >| "${cache_file}" || return 0
    fi

    source "${cache_file}"
}
__load_brew_shellenv_cache
unset -f __load_brew_shellenv_cache
