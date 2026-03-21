#!/usr/bin/env zsh

set -euo pipefail

if [[ -n "${DOTFILES_DEBUG:-}" ]]; then
    set -x
fi

SCRIPT_DIR="${${(%):-%N}:A:h}"
source "${SCRIPT_DIR}/zsh-startup-benchmark-common.sh"

#######################################
# Print command usage.
# Arguments:
#   None
# Outputs:
#   Writes usage information to stdout
# Returns:
#   0 always
#######################################
function usage() {
    cat <<'EOF'
Usage: github-action-zsh-benchmark.sh [OPTIONS]

Benchmark zsh startup for github-action-benchmark custom JSON output.

Options:
  --initial-runs N   Measure initial interactive startup N times and export mean/std in ms.
  --average-runs N   Measure warmed interactive startup N times after warmup runs.
  --keep-results     Keep intermediate hyperfine JSON files instead of removing them.
  -h, --help         Show this help message and exit.
EOF
}

initial_runs=20
average_runs=20

while (($# > 0)); do
    case "${1}" in
        --initial-runs)
            initial_runs="$(parse_positive_integer_option "${1}" "${2:-}")" || exit 1
            shift 2
            ;;
        --average-runs)
            average_runs="$(parse_positive_integer_option "${1}" "${2:-}")" || exit 1
            shift 2
            ;;
        --keep-results)
            export ZSH_STARTUP_BENCHMARK_KEEP_RESULTS='true'
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            print -u2 -- "Unknown argument: ${1}"
            usage >&2
            exit 1
            ;;
    esac
done

command -v hyperfine >/dev/null 2>&1 || {
    print -u2 -- "Required command not found: hyperfine"
    exit 1
}
command -v zsh >/dev/null 2>&1 || {
    print -u2 -- "Required command not found: zsh"
    exit 1
}

benchmark_result_dir="$(prepare_benchmark)"
trap 'cleanup_result_dir "${benchmark_result_dir}"' EXIT

measure_initial_startup_time "${benchmark_result_dir}" "${initial_runs}"
measure_average_startup_time "${benchmark_result_dir}" "${average_runs}"
record_github_action_benchmark "${benchmark_result_dir}"
