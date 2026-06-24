#!/bin/zsh

# Stop running this script if any error occurs
set -e

script_dir="${${(%):-%N}:A:h}"

source "${script_dir}/utils.sh"

#######################################
# Resolve a user-entered path with a leading tilde.
# Globals:
#   HOME
# Arguments:
#   1: Path to resolve.
# Outputs:
#   Writes the resolved path to stdout.
#######################################
function resolve_path() {
    local input_path="${1}"
    echo "${input_path/#\~/${HOME}}"
}

#######################################
# Create an SSH key when the selected key does not already exist.
# Globals:
#   None
# Arguments:
#   1: Private key path.
# Outputs:
#   Writes ssh-keygen prompts and status messages to stdout.
#######################################
function ensure_key() {
    local key_path="${1}"

    if [[ -f "${key_path}" && -f "${key_path}.pub" ]]; then
        echo "Using existing SSH key: ${key_path}"
        return 0
    fi

    if [[ -f "${key_path}" && ! -f "${key_path}.pub" ]]; then
        ssh-keygen -y -f "${key_path}" > "${key_path}.pub"
        echo "Created public key from existing private key: ${key_path}.pub"
        return 0
    fi

    local key_dir="${key_path:h}"
    mkdir -p "${key_dir}"
    chmod 700 "${key_dir}"

    printf 'What email should be used as the SSH key label? : '
    local email
    read -r email
    if [[ -z "${email}" ]]; then
        echo 'Email is required to generate an SSH key.'
        return 1
    fi

    ssh-keygen -t ed25519 -C "${email}" -f "${key_path}"
}

#######################################
# Ensure an ssh-agent is available to accept the selected key.
# Globals:
#   SSH_AUTH_SOCK
# Arguments:
#   None
# Outputs:
#   Writes ssh-agent status output when a new agent is started.
#######################################
function ensure_agent() {
    if [[ -n "${SSH_AUTH_SOCK:-}" ]]; then
        if ssh-add -l >/dev/null 2>&1; then
            return 0
        fi

        local ssh_add_status="${?}"
        if [[ "${ssh_add_status}" -eq 1 ]]; then
            return 0
        fi
    fi

    eval "$(ssh-agent -s)"
}

#######################################
# Add the SSH key to the active ssh-agent.
# Globals:
#   None
# Arguments:
#   1: Private key path.
# Outputs:
#   Writes ssh-add prompts and status messages to stdout.
#######################################
function add_key_to_agent() {
    local key_path="${1}"

    if [[ "$(uname -s)" == 'Darwin' ]]; then
        ssh-add --apple-use-keychain "${key_path}" || ssh-add "${key_path}"
    else
        ssh-add "${key_path}"
    fi
}

#######################################
# Add GitHub SSH host configuration when it does not already exist.
# Globals:
#   HOME
# Arguments:
#   1: Private key path.
# Outputs:
#   Writes status messages to stdout.
#######################################
function ensure_ssh_config() {
    local key_path="${1}"
    local config_path="${HOME}/.ssh/config"

    mkdir -p "${config_path:h}"
    chmod 700 "${config_path:h}"

    if [[ -f "${config_path}" ]] && grep -Eq '^[[:space:]]*Host[[:space:]]+.*github\.com([[:space:]]|$)' "${config_path}"; then
        echo 'SSH config already has a Host github.com block. Please verify its IdentityFile manually.'
        return 0
    fi

    cat <<EOF >> "${config_path}"

Host github.com
    HostName github.com
    User git
    IdentityFile ${key_path}
    IdentitiesOnly yes
EOF
    chmod 600 "${config_path}"
    echo "Added GitHub SSH host configuration to ${config_path}."
}

#######################################
# Upload the selected public key to the authenticated GitHub account.
# Globals:
#   None
# Arguments:
#   1: Public key path.
# Outputs:
#   Writes gh prompts and status messages to stdout.
#######################################
function upload_key() {
    local public_key_path="${1}"

    if ! __confirm "Add ${public_key_path} to your GitHub account? [y/N]: "; then
        return 0
    fi

    local title
    while [[ -z "${title}" ]]; do
        printf 'SSH key title on GitHub: '
        read -r title
        if [[ -z "${title}" ]]; then
            echo 'SSH key title is required.'
        fi
    done

    gh ssh-key add "${public_key_path}" --type authentication --title "${title}"
}

#######################################
# Show manual instructions for adding an SSH key without GitHub CLI.
# Globals:
#   None
# Arguments:
#   1: Public key path.
# Outputs:
#   Writes manual setup instructions and the public key to stdout.
#######################################
function show_manual_key_instructions() {
    local public_key_path="${1}"

    echo 'GitHub CLI was not found.'
    echo 'Install the gh command and rerun this script, or add this SSH public key to your GitHub account in a web browser:'
    echo 'https://github.com/settings/keys'
    echo ''
    echo "Public key file: ${public_key_path}"
}


#######################################
# Test SSH authentication to GitHub.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Writes ssh authentication output to stdout.
# Returns:
#   0 if GitHub reports successful authentication, non-zero otherwise.
#######################################
function test_connection() {
    local ssh_output
    local ssh_status
    if ssh_output="$(ssh -T git@github.com 2>&1)"; then
        ssh_status=0
    else
        ssh_status="${?}"
    fi

    echo "${ssh_output}"
    # GitHub reports successful authentication with exit status 1 because it
    # does not provide shell access.
    if [[ "${ssh_status}" -eq 1 && "${ssh_output}" == *'successfully authenticated'* ]]; then
        return 0
    fi

    return "${ssh_status}"
}

echo 'This script sets up GitHub SSH authentication.'
echo 'You can reuse an existing SSH key, or press Enter to use the default path and create it if needed.'
printf 'SSH private key path [~/.ssh/id_ed25519_github]: '
read -r key_path
if [[ -z "${key_path}" ]]; then
    key_path='~/.ssh/id_ed25519_github'
fi
key_path="$(resolve_path "${key_path}")"

ensure_key "${key_path}"
ensure_agent
add_key_to_agent "${key_path}"
ensure_ssh_config "${key_path}"
if command -v gh >/dev/null 2>&1; then
    upload_key "${key_path}.pub"
    test_connection
else
    show_manual_key_instructions "${key_path}.pub"
    if __confirm "Have you added the SSH key to GitHub and want to test the connection now? [y/N]: "; then
        test_connection
    fi
fi

echo 'Finished GitHub SSH configuration!'
echo ''

unset -f resolve_path
unset -f ensure_key
unset -f ensure_agent
unset -f add_key_to_agent
unset -f ensure_ssh_config
unset -f show_manual_key_instructions
unset -f upload_key
unset -f test_connection
unset -v key_path
