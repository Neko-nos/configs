autoload -Uz add-zsh-hook __python_runner __warn

typeset -g _history_last_command=""
# Zsh-native expansion is used over $(realpath $(dirname $0)) for better performance.
# Since this is a Zsh-only script, we prioritize avoiding subshells and external commands.
typeset -g _history_script_dir="${${(%):-%N}:A:h}"
typeset -g _history_warned_no_py=0


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
    local message="${1}"
    if (( _history_warned_no_py != 0 )); then
        return 0
    fi
    _history_warned_no_py=1
    __warn "${message}"
}

#######################################
# Check that the history file can be rewritten.
# Arguments:
#   1: History file path
#   2: History action name
# Outputs:
#   Writes warning to stderr
# Returns:
#   0 if the history file is writable, non-zero otherwise.
#######################################
function _history_require_writable_file() {
    emulate -L zsh
    local histfile="${1}"
    local action="${2}"
    if [[ -z "${histfile}" || ! -f "${histfile}" || ! -w "${histfile}" ]]; then
        _history_warn_once "history file is unavailable or unwritable; skipping ${action} in this session."
        return 1
    fi
    return 0
}

#######################################
# Check that this zsh session uses fcntl history locking.
# Arguments:
#   1: Warning mode, either once or always
# Outputs:
#   Writes warning to stderr
# Returns:
#   0 if hist_fcntl_lock is set, non-zero otherwise.
#######################################
function _history_require_fcntl_lock() {
    local warn_mode="${1:-once}"
    local message="hist_fcntl_lock must be set in .zshrc or equivalent so all zsh sessions use fcntl history locking."
    if [[ -o hist_fcntl_lock ]]; then
        return 0
    fi
    if [[ "${warn_mode}" == "always" ]]; then
        __warn "${message}"
    else
        _history_warn_once "${message}"
    fi
    return 1
}

#######################################
# Warn that a Python history helper cannot run.
# Arguments:
#   1: Python helper script path
#   2: History action name
# Outputs:
#   Writes warning to stderr
# Returns:
#   0 always
#######################################
function _history_warn_missing_runner() {
    emulate -L zsh
    local script="${1:t}"
    local action="${2}"
    _history_warn_once "${script} is unavailable; skipping ${action} in this session for safety."
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
    if ! _history_require_fcntl_lock once; then
        return 0
    fi

    emulate -L zsh
    if (( last_status == 0 )); then
        return 0
    fi

    local histfile="${HISTFILE:-$HOME/.zsh_history}"
    if ! _history_require_writable_file "${histfile}" "history prune"; then
        return 0
    fi

    local last_cmd="${_history_last_command}"
    if [[ -z "${last_cmd}" ]]; then
        return 0
    fi

    local prune_script="${_history_script_dir}/history_prune.py"
    if __python_runner "${prune_script}"; then
        local -a runner=("${reply[@]}")
        # Feed stdin to preserve multiline commands and avoid argument parsing pitfalls.
        # Return 0 even if the helper fails to avoid disrupting the prompt flow.
        print -rn -- "${last_cmd}" | "${runner[@]}" --status "${last_status}" --command - --histfile "${histfile}" || return 0
        return 0
    fi

    _history_warn_missing_runner "${prune_script}" "history prune"
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
    if ! _history_require_fcntl_lock once; then
        return 0
    fi

    emulate -L zsh

    local histfile="${HISTFILE:-$HOME/.zsh_history}"
    if ! _history_require_writable_file "${histfile}" "history dedup"; then
        return 0
    fi

    local dedup_script="${_history_script_dir}/history_dedup.py"
    if __python_runner "${dedup_script}"; then
        local -a runner=("${reply[@]}")
        "${runner[@]}" --histfile "${histfile}" || return 0
        return 0
    fi

    _history_warn_missing_runner "${dedup_script}" "history dedup"
    return 0
}
add-zsh-hook zshexit _history_dedup_file

#######################################
# Print decoded zsh history entries.
# Globals:
#   HISTFILE
#   HISTSIZE
# Arguments:
#   1: Optional history file path
# Outputs:
#   Writes decoded history entries to stdout
# Returns:
#   0 on success, non-zero if the history file cannot be read.
#######################################
function zsh-history() {
    emulate -L zsh
    local histfile="${1:-${HISTFILE:-$HOME/.zsh_history}}"
    if [[ -z "${histfile}" || ! -f "${histfile}" ]]; then
        return 1
    fi

    local histsize="${HISTSIZE:-10000}"
    fc -p -a "${histfile}" "${histsize}" 0 || return 1
    fc -ln 1
}

#######################################
# Ask whether interactive history editing should continue.
# Globals:
#   None
# Arguments:
#   1: History file path
# Outputs:
#   Writes a prompt to stderr
# Returns:
#   0 if editing can continue, non-zero otherwise.
#######################################
function _history_confirm_interactive_edit() {
    emulate -L zsh
    local histfile="${1}"
    if [[ ! -t 0 || ! -t 2 ]]; then
        return 0
    fi

    print -ru2 -- "IMPORTANT: For safe history editing, use this only when this is the only zsh session using ${histfile}."
    print -nu2 -- "Closing them now can also trigger that rewrite. Continue only if this is actually the only zsh process using this HISTFILE. Continue? [y/N]: "
    if read -q; then
        # Print a newline using echo because read -q doesn't.
        echo >&2
        return 0
    fi
    # Print a newline using echo because read -q doesn't.
    echo >&2
    return 1
}

#######################################
# Edit the zsh history file through a normal editor.
# Globals:
#   HISTFILE
#   HISTSIZE
# Arguments:
#   1: Optional history file path
# Outputs:
#   Writes merge notifications to stdout and warnings to stderr
# Returns:
#   0 on success, non-zero if editing fails.
#######################################
function zsh-history-edit() {
    if ! _history_require_fcntl_lock always; then
        return 1
    fi
    emulate -L zsh
    setopt hist_fcntl_lock

    local histfile="${1:-${HISTFILE:-$HOME/.zsh_history}}"
    if ! _history_require_writable_file "${histfile}" "history edit"; then
        return 1
    fi

    local edit_script="${_history_script_dir}/history_edit.py"
    if __python_runner "${edit_script}"; then
        local -a runner=("${reply[@]}")
        _history_confirm_interactive_edit "${histfile}" || return 1
        fc -W "${histfile}" || return 1
        "${runner[@]}" --histfile "${histfile}" || return 1
        fc -R "${histfile}"
        return $?
    fi

    _history_warn_missing_runner "${edit_script}" "history edit"
    return 1
}
