autoload -Uz add-zsh-hook

typeset -g _history_last_command=""
# Zsh-native expansion is used over $(realpath $(dirname $0)) for better performance.
# Since this is a Zsh-only script, we prioritize avoiding subshells and external commands.
typeset -g _history_script_dir="${${(%):-%N}:A:h}"
typeset -g _history_warned_no_py=0


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
function __warn () {
    echo "\033[33mWarning:\033[m" "$*"
}

#######################################
# Emit a warning once per session.
# Globals:
#   _history_warned_no_py
# Arguments:
#   1: Warning message
# Outputs:
#   Writes warning to stderr
# Returns:
#   0 always
#######################################
function _history_warn_once() {
    emulate -L zsh
    local message="$1"
    if (( _history_warned_no_py != 0 )); then
        return 0
    fi
    _history_warned_no_py=1
    if typeset -f __warn >/dev/null 2>&1; then
        __warn "$message"
    else
        echo "Warning: $message" >&2
    fi
}

#######################################
# Capture the last executed command for history filtering.
# Globals:
#   _history_last_command
# Arguments:
#   1: Command line before execution
# Outputs:
#   None
# Returns:
#   0 always
#######################################
function _history_capture_command() {
    emulate -L zsh
    _history_last_command="$1"
}
add-zsh-hook preexec _history_capture_command

#######################################
# Remove failed commands from the history file while keeping
# them in the in-memory history list.
# Globals:
#   HISTFILE
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   0 if the function ran without fatal errors.
#######################################
function _history_prune_failed_file() {
    local last_status=$?
    emulate -L zsh
    if (( last_status == 0 )); then
        return 0
    fi

    local histfile="${HISTFILE:-$HOME/.zsh_history}"
    if [[ -z "${histfile}" || ! -f "${histfile}" || ! -w "${histfile}" ]]; then
        _history_warn_once '$HISTFILE is unavailable or unwritable; skipping history prune in this session.'
        return 0
    fi

    local last_cmd="${_history_last_command}"
    if [[ -z "${last_cmd}" ]]; then
        return 0
    fi

    # We should use a language that properly handles multiline commands (we should not use awk/sed).
    local prune_script="${_history_script_dir}/history_prune.py"
    # Use an array to preserve argument boundaries and avoid word splitting issues.
    local -a runner=()
    if command -v uv >/dev/null 2>&1 && [[ -f "${prune_script}" ]]; then
        runner=(uv run "${prune_script}")
    elif command -v python >/dev/null 2>&1 && [[ -f "${prune_script}" ]]; then
        runner=(python "${prune_script}")
    elif command -v python3 >/dev/null 2>&1 && [[ -f "${prune_script}" ]]; then
        runner=(python3 "${prune_script}")
    fi

    if (( ${#runner[@]} > 0 )); then
        # Feed stdin to preserve multiline commands and avoid argument parsing pitfalls.
        # Return 0 even if the helper fails to avoid disrupting the prompt flow.
        print -rn -- "${last_cmd}" | "${runner[@]}" --status "${last_status}" --command - --histfile "${histfile}" || return 0
        return 0
    fi

    _history_warn_once "history_prune.py is unavailable; skipping history prune in this session for safety."
    return 0
}
add-zsh-hook precmd _history_prune_failed_file

#######################################
# Deduplicate the history file by command, keeping the latest entry.
# Globals:
#   HISTFILE
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   0 if the function ran without fatal errors.
#######################################
function _history_dedup_file() {
    emulate -L zsh

    local histfile="${HISTFILE:-$HOME/.zsh_history}"
    if [[ -z "${histfile}" || ! -f "${histfile}" || ! -w "${histfile}" ]]; then
        _history_warn_once '$HISTFILE is unavailable or unwritable; skipping history dedup in this session.'
        return 0
    fi

    local dedup_script="${_history_script_dir}/history_dedup.py"
    local -a runner=()
    if command -v uv >/dev/null 2>&1 && [[ -f "${dedup_script}" ]]; then
        runner=(uv run "${dedup_script}")
    elif command -v python >/dev/null 2>&1 && [[ -f "${dedup_script}" ]]; then
        runner=(python "${dedup_script}")
    elif command -v python3 >/dev/null 2>&1 && [[ -f "${dedup_script}" ]]; then
        runner=(python3 "${dedup_script}")
    fi

    if (( ${#runner[@]} > 0 )); then
        "${runner[@]}" --histfile "${histfile}" || return 0
        return 0
    fi

    _history_warn_once "history_dedup.py is unavailable; skipping history dedup in this session for safety."
    return 0
}
add-zsh-hook zshexit _history_dedup_file
