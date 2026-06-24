#!/bin/zsh

# Stop running this script if any error occurs
set -e

script_dir="${${(%):-%N}:A:h}"

source "${script_dir}/utils.sh"

#######################################
# Configure the official GitHub CLI apt repository.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Writes apt repository setup status to stdout and stderr.
#######################################
function configure_gh_apt_repository() {
    local source_list='/etc/apt/sources.list.d/github-cli.list'
    if [[ -f "${source_list}" ]]; then
        echo 'GitHub CLI apt repository is already configured.'
        return 0
    fi

    sudo mkdir -p -m 755 /etc/apt/keyrings
    wget -nv -O - https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg

    sudo mkdir -p -m 755 /etc/apt/sources.list.d
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo tee "${source_list}" >/dev/null
}

configure_gh_apt_repository
__install_package gh

echo 'Finished GitHub CLI configuration!'
echo ''

unset -f configure_gh_apt_repository
