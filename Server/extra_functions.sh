# shellcheck shell=bash

#######################################
# Refresh shared sessions before opening Codex's resume or fork picker.
# Globals:
#   HOME
# Arguments:
#   Codex CLI arguments.
# Outputs:
#   Writes Codex output to stdout and stderr.
# Returns:
#   The refresh command's nonzero status if refreshing sessions fails.
#######################################
function codex() {
    case "${1:-}" in
        resume | fork)
            uv run --no-project "${HOME}/configs/Server/refresh_codex_sessions.py" || return
            ;;
    esac
    command codex "$@"
}
