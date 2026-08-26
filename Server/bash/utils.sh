# shellcheck shell=bash

#######################################
# Emit a warning message.
# Globals:
#   None
# Arguments:
#   1: Warning message
# Outputs:
#   Writes warning to stderr
# Returns:
#   0 always
#######################################
function __warn() {
    printf '\033[33mWarning:\033[0m %s\n' "$*" >&2
}

#######################################
# Refresh generated shell code when inputs or the generator executable change.
# Globals:
#   None
# Arguments:
#   1: Command name used to generate the cache
#   2: Cache file path
#   3..N-1: Watched file paths before `--`
#   After `--`: Arguments passed to the command
# Outputs:
#   Writes warnings to stderr when cache generation fails
# Returns:
#   0 on success, non-zero on cache generation failure.
#######################################
function __update_cache() {
    if (( $# < 3 )); then
        __warn "Usage: __update_cache <command> <cache_file> [watched_files...] -- [command_args...]"
        return 1
    fi

    local command_name="$1"
    local cache_file="$2"
    shift 2

    local -a watched_files=()
    while (( $# > 0 )) && [[ "$1" != "--" ]]; do
        watched_files+=("$1")
        shift
    done
    shift

    if ! hash "${command_name}" 2>/dev/null || [[ -z "${BASH_CMDS[$command_name]-}" ]]; then
        __warn "Required command not found: ${command_name}"
        return 1
    fi
    local command_path="${BASH_CMDS[$command_name]}"

    local needs_update=0
    if [[ ! -r "${cache_file}" || "${command_path}" -nt "${cache_file}" ]]; then
        needs_update=1
    else
        local watched_file
        for watched_file in "${watched_files[@]}"; do
            if [[ ! -e "${watched_file}" || "${watched_file}" -nt "${cache_file}" ]]; then
                needs_update=1
                break
            fi
        done
    fi
    if (( needs_update == 0 )); then
        return 0
    fi

    mkdir -p "$(dirname "${cache_file}")"

    local tmp_cache="${cache_file}.tmp.$$"

    if ! "${command_path}" "$@" >| "${tmp_cache}"; then
        __warn "Failed to update cache '${cache_file}' with '${command_name} $*'."
        rm -f "${tmp_cache}"
        return 1
    fi

    mv "${tmp_cache}" "${cache_file}"
}
