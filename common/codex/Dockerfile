FROM nvidia/cuda:12.8.0-devel-ubuntu24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG CONFIGS_REPOSITORY=https://github.com/Neko-nos/configs.git
ARG USERNAME=ubuntu

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV CODEX_HOME=/home/${USERNAME}/.codex
ENV NPM_CONFIG_PREFIX=/home/${USERNAME}/.local
ENV PATH=/home/${USERNAME}/.local/bin:${PATH}
ENV SHELL=/bin/zsh

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# ref: https://github.com/verl-project/verl/blob/41a52449db58996731f54b79d20b939f5297fc4d/docker/Dockerfile.stable.vllm#L29
RUN apt-get update && apt-get install -y \
        git \
        wget \
        curl \
        cmake \
        build-essential \
        libibverbs-dev \
        libnuma-dev \
        librdmacm-dev \
        numactl \
        software-properties-common \
        ca-certificates \
        sudo \
        zsh \
    && rm -rf /var/lib/apt/lists/*

RUN usermod --shell /bin/zsh "${USERNAME}" \
    && install -d -m 0755 /etc/sudoers.d \
    && printf '%s ALL=(ALL) NOPASSWD:ALL\n' "${USERNAME}" > "/etc/sudoers.d/${USERNAME}" \
    && chmod 0440 "/etc/sudoers.d/${USERNAME}"

USER ${USERNAME}
WORKDIR /home/${USERNAME}

RUN mkdir -p "${CODEX_HOME}" "${NPM_CONFIG_PREFIX}/bin" \
    && git clone "${CONFIGS_REPOSITORY}" "${HOME}/configs"

WORKDIR /workspace

CMD ["/bin/zsh", "-lc", "echo 'To finish setup, run: cd ~/configs/Ubuntu/install && zsh ./install.sh'; exec /bin/zsh"]
