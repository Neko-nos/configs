#!/usr/bin/env zsh

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
# Validate and echo a positive integer CLI option value.
# Arguments:
#   1: Option name
#   2: Option value
# Outputs:
#   Writes the validated value to stdout
#   Writes an error message to stderr on validation failure
# Returns:
#   0 when the value is a positive integer, 1 otherwise
#######################################
function parse_positive_integer_option() {
    local option_name="${1}"
    local option_value="${2:-}"

    if [[ -z "${option_value}" || "${option_value}" == -* ]]; then
        print -u2 -- "${option_name} requires 1 argument: a positive integer."
        return 1
    fi

    if [[ ! "${option_value}" =~ '^[1-9][0-9]*$' ]]; then
        print -u2 -- "${option_name} must be a positive integer: ${option_value}"
        return 1
    fi

    print -r -- "${option_value}"
}

#######################################
# Remove the temporary benchmark directory unless cleanup is disabled.
# Globals:
#   ZSH_STARTUP_BENCHMARK_KEEP_RESULTS
# Arguments:
#   1: Temporary directory path
# Outputs:
#   Writes the preserved directory path to stdout when cleanup is disabled
# Returns:
#   0 on success, non-zero on failure
#######################################
function cleanup_result_dir() {
    local target_dir="${1}"
    [[ -d "${target_dir}" ]] || return 0

    if [[ "${ZSH_STARTUP_BENCHMARK_KEEP_RESULTS:-false}" == 'true' ]]; then
        print -u2 -r -- "Preserved benchmark results at ${target_dir}"
        return 0
    fi

    command rm -r -- "${target_dir}"
}

#######################################
# Measure the first interactive zsh startup time.
# Globals:
#   ZSH_STARTUP_BENCHMARK_COMMAND
# Arguments:
#   1: Benchmark result directory
#   2: Number of benchmark runs
# Outputs:
#   None
# Returns:
#   0 on success, non-zero on failure
#######################################
function measure_initial_startup_time() {
    local benchmark_result_dir="${1}"
    local benchmark_runs="${2}"

    measure_startup_time "${benchmark_result_dir}" "zsh-initial-startup-time.json" 0 "${benchmark_runs}"
}

#######################################
# Measure the average interactive zsh startup time.
# Globals:
#   ZSH_STARTUP_BENCHMARK_COMMAND
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

    measure_startup_time "${benchmark_result_dir}" "zsh-average-startup-time.json" 5 "${benchmark_runs}"
}

#######################################
# Measure interactive zsh startup time with hyperfine.
# Globals:
#   ZSH_STARTUP_BENCHMARK_COMMAND
# Arguments:
#   1: Benchmark result directory
#   2: Output file name
#   3: Number of warmup runs
#   4: Number of measured runs
# Outputs:
#   None
# Returns:
#   0 on success, non-zero on failure
#######################################
function measure_startup_time() {
    local benchmark_result_dir="${1}"
    local output_file_name="${2}"
    local warmup_runs="${3}"
    local benchmark_runs="${4}"
    local benchmark_command="${ZSH_STARTUP_BENCHMARK_COMMAND:-zsh -i -c exit}"

    hyperfine \
        --warmup "${warmup_runs}" \
        --runs "${benchmark_runs}" \
        --export-json "${benchmark_result_dir}/${output_file_name}" \
        "${benchmark_command}" \
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
    local metric_value

    metric_value="$(
        sed -n "s/.*\"${metric_name}\": \\([0-9.eE+-]*\\|null\\).*/\\1/p" "${result_file}" | head -n 1
    )"

    if [[ -z "${metric_value}" || "${metric_value}" == 'null' ]]; then
        print -r -- '0'
        return 0
    fi

    print -r -- "${metric_value}"
}

#######################################
# Convert seconds to milliseconds.
# Arguments:
#   1: Duration in seconds
# Outputs:
#   Writes the converted value in milliseconds to stdout
# Returns:
#   0 on success, non-zero on failure
#######################################
function seconds_to_milliseconds() {
    local seconds="${1}"
    awk -v seconds="${seconds}" 'BEGIN { printf "%.6f", seconds * 1000 }'
}

#######################################
# Read benchmark summary metrics for both startup measurements.
# Arguments:
#   1: Benchmark result directory
# Outputs:
#   Writes initial mean, initial std, average mean, average std on separate lines
# Returns:
#   0 on success, non-zero on failure
#######################################
function read_benchmark_summary() {
    local benchmark_result_dir="${1}"
    local initial_file="${benchmark_result_dir}/zsh-initial-startup-time.json"
    local average_file="${benchmark_result_dir}/zsh-average-startup-time.json"
    local initial_mean
    local initial_std
    local average_mean
    local average_std

    initial_mean="$(read_result_metric "${initial_file}" "mean")"
    initial_std="$(read_result_metric "${initial_file}" "stddev")"
    average_mean="$(read_result_metric "${average_file}" "mean")"
    average_std="$(read_result_metric "${average_file}" "stddev")"

    printf '%s\n%s\n%s\n%s\n' \
        "${initial_mean}" \
        "${initial_std}" \
        "${average_mean}" \
        "${average_std}"
}

#######################################
# Record the benchmark results as JSON for the local hook.
# Arguments:
#   1: Benchmark result directory
#   2: Number of initial startup runs
#   3: Number of average startup runs
# Outputs:
#   Writes the benchmark summary as JSON to stdout
# Returns:
#   0 on success, non-zero on failure
#######################################
function record_startup_time() {
    local benchmark_result_dir="${1}"
    local initial_runs="${2}"
    local average_runs="${3}"
    local initial_mean
    local initial_std
    local average_mean
    local average_std

    {
        IFS=$'\n' read -r initial_mean
        IFS=$'\n' read -r initial_std
        IFS=$'\n' read -r average_mean
        IFS=$'\n' read -r average_std
    } < <(read_benchmark_summary "${benchmark_result_dir}")

    cat <<EOF
[
    {
        "name": "zsh initial startup time",
        "unit": "Second",
        "mean": ${initial_mean},
        "std": ${initial_std},
        "runs": ${initial_runs}
    },
    {
        "name": "zsh average startup time",
        "unit": "Second",
        "mean": ${average_mean},
        "std": ${average_std},
        "runs": ${average_runs}
    }
]
EOF
}

#######################################
# Record benchmark results for github-action-benchmark custom input.
# Arguments:
#   1: Benchmark result directory
# Outputs:
#   Writes the benchmark summary as JSON to stdout
# Returns:
#   0 on success, non-zero on failure
#######################################
function record_github_action_benchmark() {
    local benchmark_result_dir="${1}"
    local initial_mean
    local initial_std
    local average_mean
    local average_std
    local initial_mean_ms
    local initial_std_ms
    local average_mean_ms
    local average_std_ms

    {
        IFS=$'\n' read -r initial_mean
        IFS=$'\n' read -r initial_std
        IFS=$'\n' read -r average_mean
        IFS=$'\n' read -r average_std
    } < <(read_benchmark_summary "${benchmark_result_dir}")

    initial_mean_ms="$(seconds_to_milliseconds "${initial_mean}")"
    initial_std_ms="$(seconds_to_milliseconds "${initial_std}")"
    average_mean_ms="$(seconds_to_milliseconds "${average_mean}")"
    average_std_ms="$(seconds_to_milliseconds "${average_std}")"

    cat <<EOF
[
    {
        "name": "zsh initial startup time",
        "unit": "ms",
        "value": ${initial_mean_ms},
        "range": "± ${initial_std_ms}"
    },
    {
        "name": "zsh average startup time",
        "unit": "ms",
        "value": ${average_mean_ms},
        "range": "± ${average_std_ms}"
    }
]
EOF
}
