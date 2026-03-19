#!/usr/bin/env zsh

set -euo pipefail

if [[ -n "${DOTFILES_DEBUG:-}" ]]; then
    set -x
fi

SCRIPT_DIR="${${(%):-%N}:A:h}"

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
Usage: pre-push-zsh-benchmark.sh [--runs N]

Benchmark zsh startup with hyperfine before push.
EOF
}

#######################################
# Create a temporary directory for benchmark results.
# Arguments:
#   None
# Outputs:
#   Writes the temporary directory path to stdout
# Returns:
#   0 on success, non-zero on failure
#######################################
function prepare_benchmark() {
    local tmp_dir
    tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/zsh-startup-benchmark.XXXXXX")"
    print -r -- "${tmp_dir}"
}

#######################################
# Remove the temporary benchmark directory.
# Arguments:
#   1: Temporary directory path
# Outputs:
#   None
# Returns:
#   0 on success, non-zero on failure
#######################################
function cleanup_result_dir() {
    local target_dir="${1}"
    [[ -d "${target_dir}" ]] || return 0
    # Use `command` to bypass aliases/functions such as `rm -i`; `builtin` is
    # not applicable here because `rm` is an external command, not a shell builtin.
    command rm -r -- "${target_dir}"
}

#######################################
# Measure the first interactive zsh startup time.
# Arguments:
#   1: Benchmark result directory
# Outputs:
#   None
# Returns:
#   0 on success, non-zero on failure
#######################################
function measure_initial_startup_time() {
    local benchmark_result_dir="${1}"

    hyperfine \
        --warmup 0 \
        --runs 1 \
        --export-json "${benchmark_result_dir}/zsh-initial-startup-time.json" \
        'zsh -i -c exit' \
        >/dev/null
}

#######################################
# Measure the average interactive zsh startup time.
# Arguments:
#   1: Benchmark result directory
#   2: Number of benchmark runs
# Outputs:
#   None
# Returns:
#   0 on success, non-zero on failure
#######################################
function measure_average_startup_time() {
    local benchmark_result_dir="${1}"
    local benchmark_runs="${2}"

    hyperfine \
        --warmup 5 \
        --runs "${benchmark_runs}" \
        --export-json "${benchmark_result_dir}/zsh-average-startup-time.json" \
        'zsh -i -c exit' \
        >/dev/null
}

#######################################
# Extract a numeric metric from a hyperfine JSON result.
# Arguments:
#   1: Hyperfine JSON result file
#   2: Metric key name
# Outputs:
#   Writes the parsed metric value to stdout
# Returns:
#   0 on success, non-zero on failure
#######################################
function read_result_metric() {
    local result_file="${1}"
    local metric_name="${2}"

    sed -n "s/.*\"${metric_name}\": \\([0-9.]*\\).*/\\1/p" "${result_file}" | head -n 1
}

#######################################
# Record the benchmark results as JSON.
# Arguments:
#   1: Benchmark result directory
# Outputs:
#   Writes the benchmark summary to stdout
# Returns:
#   0 on success, non-zero on failure
#######################################
function record_startup_time() {
    local benchmark_result_dir="${1}"
    local initial_file="${benchmark_result_dir}/zsh-initial-startup-time.json"
    local average_file="${benchmark_result_dir}/zsh-average-startup-time.json"
    # Keep declaration separate from command substitution so failures propagate
    # correctly under `set -e` in zsh.
    local initial_time
    local average_mean
    local average_std

    initial_time="$(read_result_metric "${initial_file}" "mean")"
    average_mean="$(read_result_metric "${average_file}" "mean")"
    average_std="$(read_result_metric "${average_file}" "stddev")"

    cat <<EOF
[
    {
        "name": "zsh initial startup time",
        "unit": "Second",
        "time": ${initial_time},
    },
    {
        "name": "zsh average startup time",
        "unit": "Second",
        "mean": ${average_mean},
        "std": ${average_std}
    },
]
EOF
}

benchmark_runs=10

while (($# > 0)); do
    case "${1}" in
        --runs)
            benchmark_runs="${2:-10}"
            if (($# > 1)); then
                shift 2
            else
                shift
            fi
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

measure_initial_startup_time "${benchmark_result_dir}"
measure_average_startup_time "${benchmark_result_dir}" "${benchmark_runs}"
record_startup_time "${benchmark_result_dir}"
