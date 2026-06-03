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
