#!/bin/zsh

# Stop running this script if any error occurs
set -e

script_dir="${${(%):-%N}:A:h}"

source "${script_dir}/utils.sh"

#######################################
# Install Docker Engine from Docker's official apt repository.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Writes apt and setup progress to stdout.
# Returns:
#   Exit status of the last installation command run.
#######################################
function __install_docker_engine() {
    # ref: https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl

    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    local architecture="$(dpkg --print-architecture)"
    local ubuntu_codename="$(
        . /etc/os-release
        echo "${UBUNTU_CODENAME:-${VERSION_CODENAME}}"
    )"

    printf '%s\n' \
        'Types: deb' \
        'URIs: https://download.docker.com/linux/ubuntu' \
        "Suites: ${ubuntu_codename}" \
        'Components: stable' \
        "Architectures: ${architecture}" \
        'Signed-By: /etc/apt/keyrings/docker.asc' \
        | sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null

    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # ref: https://code.visualstudio.com/docs/devcontainers/containers#_installation
    if ! getent group docker >/dev/null; then
        sudo groupadd docker
    fi
    sudo usermod -aG docker "${USER}"
    sudo systemctl enable --now docker
}

#######################################
# Install NVIDIA Container Toolkit and configure Docker's NVIDIA runtime.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Writes apt and setup progress to stdout.
# Returns:
#   Exit status of the last installation command run.
#######################################
function __install_nvidia_container_toolkit() {
    # ref: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html#with-apt-ubuntu-debian
    if ! command -v docker >/dev/null 2>&1; then
        echo 'Docker Engine is required before configuring NVIDIA Container Toolkit for Docker.' >&2
        return 1
    fi

    sudo apt-get update
    sudo apt-get install -y --no-install-recommends ca-certificates curl gnupg2

    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
        | sudo gpg --dearmor --yes -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

    curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
        | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
        | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list >/dev/null

    sudo apt-get update
    # ref: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/arch-overview.html#which-package-should-i-use-then
    sudo apt-get install -y nvidia-container-toolkit

    # ref: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html#configuring-docker
    sudo nvidia-ctk runtime configure --runtime=docker
    sudo systemctl restart docker
}

if __confirm 'Install Docker Engine? [y/N]: '; then
    __install_docker_engine
else
    echo 'Skipping Docker Engine installation.'
fi
echo

if __confirm 'Install NVIDIA Container Toolkit and configure Docker GPU access? [y/N]: '; then
    __install_nvidia_container_toolkit
else
    echo 'Skipping NVIDIA Container Toolkit installation.'
fi
echo

echo 'Docker/GPU setup complete.'
echo 'Test Docker with: docker run --rm hello-world'
echo 'For GPU access, test with an NVIDIA CUDA image and nvidia-smi.'
echo 'If docker requires sudo before restarting WSL, start a new login shell so the docker group membership is applied.'
