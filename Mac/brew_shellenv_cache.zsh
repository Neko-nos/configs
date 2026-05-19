#######################################
# Load cached Homebrew shell environment.
# Globals:
#   XDG_CACHE_HOME
#   HOME
# Arguments:
#   None
# Outputs:
#   Writes warnings to stderr when cache generation fails
# Returns:
#   0 on success, non-zero on cache generation failure.
#######################################
function __load_brew_shellenv_cache() {
    emulate -L zsh -o extended_glob

    local brew_cmd="/opt/homebrew/bin/brew"
    local cache_file="${XDG_CACHE_HOME:-${HOME}/.cache}/zprofile/brew-shellenv.zsh"
    local tmp_cache="${cache_file}.tmp.$$"
    if [[ ! -x "${brew_cmd}" ]]; then
        return 0
    fi

    if [[ ! -r "${cache_file}" || -n "${cache_file}"(#qN.mh+24) ]]; then
        mkdir -p "${cache_file:h}"
        if ! "${brew_cmd}" shellenv >| "${tmp_cache}"; then
            print -u2 -- "Warning: Failed to update Homebrew shellenv cache: ${cache_file}"
            return 1
        fi
        mv "${tmp_cache}" "${cache_file}"
    fi

    source "${cache_file}"
}
__load_brew_shellenv_cache
unset -f __load_brew_shellenv_cache
