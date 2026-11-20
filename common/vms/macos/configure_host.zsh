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
    StrictHostKeyChecking accept-new
    ProxyCommand /bin/sh -c 'exec /usr/bin/nc "\$(${commands[tart]} ip ${vm_name} --wait 120)" %p'

.
w
EOF
fi
chmod 600 "${config_path}"

# Permit only this VM alias to leave the host sandbox; all trailing arguments run in the guest.
cat >"${HOME}/.codex/rules/tart-vm-${vm_name}.rules" <<EOF
# Keep the host sandboxed while allowing unrestricted commands only inside this VM.
prefix_rule(
    pattern=["ssh", "${vm_name}"],
    decision="allow",
    justification="Allow unrestricted commands inside the isolated ${vm_name} VM",
)
EOF

antigravity_settings_path="${HOME}/.gemini/antigravity-cli/settings.json"
if [[ -f "${antigravity_settings_path}" ]]; then
    python3 - "${antigravity_settings_path}" "command(ssh ${vm_name})" "command(ssh -tt ${vm_name})" <<'PY'
import json
import sys

settings_path = sys.argv[1]
rules = sys.argv[2:]
with open(settings_path, encoding="utf-8") as f:
    settings = json.load(f)

allow = settings.setdefault("permissions", {}).setdefault("allow", [])
changed = False
for rule in rules:
    if rule not in allow:
        allow.append(rule)
        changed = True

if changed:
    with open(settings_path, "w", encoding="utf-8") as f:
        json.dump(settings, f, indent=2)
        f.write("\n")
PY
fi
