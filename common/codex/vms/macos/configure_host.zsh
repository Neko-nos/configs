#!/usr/bin/env zsh

set -euo pipefail

vm_name="${1}"
ssh_dir="${HOME}/.ssh"
config_path="${ssh_dir}/config"
identity_path="${ssh_dir}/id_ed25519_${vm_name}"

mkdir -p "${ssh_dir}" "${HOME}/.codex/rules"
chmod 700 "${ssh_dir}"

if [[ ! -f "${identity_path}" ]]; then
    ssh-keygen -q -t ed25519 -N '' -C "${vm_name}" -f "${identity_path}"
fi

touch "${config_path}"
if ! grep -Fqx "Host ${vm_name}" "${config_path}"; then
    # OpenSSH keeps the first value found, so this must precede a broad Host * block.
    # Resolve Tart's changing IP at connection time and retain its non-interactive executable path.
    /bin/ed -s "${config_path}" <<EOF
0a
Host ${vm_name}
    User admin
    IdentityFile ${identity_path}
    IdentitiesOnly yes
    StrictHostKeyChecking yes
    ProxyCommand /bin/sh -c 'exec /usr/bin/nc "\$(${commands[tart]} ip ${vm_name} --wait 120)" %p'

.
w
EOF
fi
chmod 600 "${config_path}"

# Permit only this VM alias to leave the host sandbox; all trailing arguments run in the guest.
cat > "${HOME}/.codex/rules/tart-vm-${vm_name}.rules" <<EOF
# Keep the host sandboxed while allowing unrestricted commands only inside this VM.
prefix_rule(
    pattern=["ssh", "${vm_name}"],
    decision="allow",
    justification="Allow unrestricted commands inside the isolated ${vm_name} VM",
)
EOF
