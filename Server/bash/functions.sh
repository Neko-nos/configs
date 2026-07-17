# shellcheck shell=bash

#######################################
# Run Ruff autofix (linter), import sorting, and formatting for the given targets.
# Arguments:
#   Ruff target paths or options.
# Outputs:
#   Writes Ruff output to stdout and stderr
# Returns:
#   0 if all Ruff commands succeed, non-zero otherwise.
#######################################
function ruff-fix() {
    if (($# == 0)); then
        printf "usage: ruff-fix <path-or-ruff-options>...\n" >&2
        return 2
    fi

    local -a ruff_cmd
    if command -v ruff >/dev/null 2>&1; then
        ruff_cmd=(ruff)
    elif command -v uv >/dev/null 2>&1; then
        ruff_cmd=(uv run ruff)
    elif command -v uvx >/dev/null 2>&1; then
        ruff_cmd=(uvx ruff)
    else
        printf "ruff-fix: ruff, uv, and uvx are unavailable.\n" >&2
        return 127
    fi

    "${ruff_cmd[@]}" check "$@" --fix
    "${ruff_cmd[@]}" check "$@" --fix --select I
    "${ruff_cmd[@]}" format "$@"
}

#######################################
# Append the current directory to the persistent recent-directory log.
# Globals:
#   HOME
#   PWD
#   XDG_CACHE_HOME
# Arguments:
#   None
# Returns:
#   0 on success, non-zero if the cache cannot be updated.
#######################################
function _record_cdr() {
    local cache_dir="${XDG_CACHE_HOME:-${HOME}/.cache}"
    local cache_file="${cache_dir}/bash-recent-dirs"
    local latest_dir

    if [[ -r "${cache_file}" ]]; then
        latest_dir="$(tail -n 1 "${cache_file}")" || return 1
        if [[ "${latest_dir}" == "${PWD}" ]]; then
            return 0
        fi
    else
        mkdir -p "${cache_dir}" || return 1
    fi

    printf "%s\n" "${PWD}" >>"${cache_file}"
}

#######################################
# Select a recent directory using fzf.
# Globals:
#   HOME
#   PWD
#   XDG_CACHE_HOME
# Arguments:
#   None
# Outputs:
#   Writes a shell-escaped cd command to stdout.
#######################################
function search_cdr() {
    local cache_file="${XDG_CACHE_HOME:-${HOME}/.cache}/bash-recent-dirs"
    local escaped_dir
    local selected_dir

    selected_dir="$(
        awk '
            { directories[NR] = $0 }
            END {
                for (i = NR; i >= 1; i--) {
                    directory = directories[i]
                    if (directory != ENVIRON["PWD"] && !seen[directory]++) {
                        print directory
                    }
                }
            }
        ' "${cache_file}" |
            fzf --prompt="cdr >"
    )" || return 0

    if [[ -n "${selected_dir}" ]]; then
        printf -v escaped_dir "%q" "${selected_dir}"
        printf "cd %s" "${escaped_dir}"
    fi
}
# Native Readline must execute cd through accept-line to refresh the prompt.
bind -m emacs-standard '"\C-\e(": redraw-current-line'
# Keep the command substitution literal until Readline invokes the macro.
# shellcheck disable=SC2016
bind -m emacs-standard '"\C-p": " \C-b\C-k \C-u`search_cdr`\e\C-e\C-\e(\C-m\C-y\C-h\e \C-y\ey\C-x\C-x\C-d\C-y\ey\C-_"'

#######################################
# Expand repeated dots into parent-directory paths while editing a command.
# Globals:
#   READLINE_LINE
#   READLINE_POINT
# Arguments:
#   None
#######################################
function replace_multiple_dots() {
    local before="${READLINE_LINE:0:READLINE_POINT}"
    local after="${READLINE_LINE:READLINE_POINT}"

    if [[ "${before}" == *.. ]]; then
        before="${before%??}../.."
    else
        before="${before}."
    fi

    READLINE_LINE="${before}${after}"
    READLINE_POINT="${#before}"
}
bind -x '".": replace_multiple_dots'

#######################################
# Select a command from the complete Bash history using fzf.
# Globals:
#   HISTFILE
#   READLINE_LINE
#   READLINE_POINT
# Arguments:
#   None
#######################################
function search_history() {
    local output
    local script

    # Include commands written by other sessions before building the choices.
    builtin history -a
    builtin history -n

    # fc prefixes each history entry with a tab, which lets awk preserve
    # multiline commands while converting the entries to NUL-delimited records.
    # Keep awk variables literal until awk evaluates the program.
    # shellcheck disable=SC2016
    script='function emit(entry) {
        sub(/^[ *]/, "", entry)
        if (!seen[entry]++) {
            printf "%s%c", entry, 0
        }
    }
    NR == 1 {
        entry = substr($0, 2)
        next
    }
    /^\t/ {
        emit(entry)
        entry = substr($0, 2)
        next
    }
    {
        entry = entry ORS $0
    }
    END {
        if (NR) {
            emit(entry)
        }
    }'

    output="$({
        set +o pipefail
        builtin fc -lnr -2147483648 2>/dev/null |
            awk "${script}" |
            fzf --read0 --query "${READLINE_LINE:0:READLINE_POINT}"
    })" || return 0

    if [[ -n "${output}" ]]; then
        READLINE_LINE="${output}"
        READLINE_POINT="${#READLINE_LINE}"
    fi
}
bind -x '"\C-r": search_history'
