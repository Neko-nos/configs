FROM ubuntu:24.04

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

RUN apt-get update && apt-get install -y \
        build-essential \
        ca-certificates \
        cmake \
        curl \
        git \
        git-lfs \
        software-properties-common \
        sudo \
        wget \
        zsh \
    && rm -rf /var/lib/apt/lists/*

RUN usermod --shell /bin/zsh "${USERNAME}" \
    && install -d -m 0755 /etc/sudoers.d \
    && printf '%s ALL=(ALL) NOPASSWD:ALL\n' "${USERNAME}" > "/etc/sudoers.d/${USERNAME}" \
    && chmod 0440 "/etc/sudoers.d/${USERNAME}"

USER ${USERNAME}
WORKDIR /home/${USERNAME}

# Codex may still apply its sandbox unless full access is also the configured default.
# ref: https://learn.chatgpt.com/docs/sandboxing?surface=cli#cli-configure-defaults
RUN mkdir -p "${CODEX_HOME}" "${NPM_CONFIG_PREFIX}/bin" \
    && git clone "${CONFIGS_REPOSITORY}" "${HOME}/configs" \
    && sed -i 's/^default_permissions = .*/default_permissions = ":danger-full-access"/' "${HOME}/configs/common/codex/config.toml" \
    && sed -i 's/^approval_policy = .*/approval_policy = "never"/' "${HOME}/configs/common/codex/config.toml"

WORKDIR /workspace

CMD ["/bin/zsh", "-lc", "echo 'To finish setup, run: cd ~/configs/Ubuntu/install && zsh ./install.sh'; exec /bin/zsh"]
