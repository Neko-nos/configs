---
name: operate-tart-vm
description: Operate a user-selected Tart macOS VM with guest administrative access while keeping the host isolated. Use for tasks requiring macOS, a fresh environment, GUI interaction, or guest system permissions.
---

# Run Tasks in a Tart macOS VM

## Confirm the target

Run `command tart list`. Verify a user-provided VM name exists. Otherwise, inspect the names,
sources, and states, then ask the user to confirm the plausible target or select among candidates.
Do not infer a local VM from an OCI cache entry.

When the task requires a fresh environment, verify that the confirmed VM has the requested state.
Do not reset, replace, or recreate it unless the user requested that operation.

## Start and verify the VM

After confirmation, start the VM in a retained PTY session using the literal VM name directly
(avoid shell variable expansion so command-prefix allow rules match cleanly):

```console
command tart run --vnc-experimental --no-graphics <confirmed-vm-name>
```

Keep the Tart session open and read the current VNC endpoint from its output. Do not add `--dir`,
including read-only host mounts. Stop if the VM exposes host files, applications, or credentials.

Use the confirmed VM name as its `~/.ssh/config` alias:

```console
ssh <confirmed-vm-name> 'sw_vers; id; mount; sudo -n true && echo guest-sudo-ready'
```

Verify the expected macOS guest, guest `sudo`, and absence of host `virtiofs` shares. If SSH or
Packer fails immediately with `No route to host`, macOS Local Network privacy is likely blocking
the terminal or a stale `tmux` server's responsible app; verify Local Network permission and
restart any `tmux` server started under an earlier app instance.

## Run guest commands

Run guest commands through the confirmed SSH alias:

```console
ssh <confirmed-vm-name> '<guest command>'
```

For interactive terminal programs:

```console
ssh -tt <confirmed-vm-name> 'cd "<guest-workdir>" && exec <command>'
```

Answer one prompt at a time and inspect the result. Use a PTY for zsh `read -q`; do not pipe
`yes` or fixed responses into interactive programs.

When testing working-tree changes, use the current content rather than reconstructed `main` or
`HEAD` content. Inspect `git status` and `git diff`, including relevant untracked files, before
selecting inputs.

When the guest needs host files:

1. Select only the files required by the task.
2. Check that they contain no unrelated data or secrets.
3. Transfer them with `scp` to a new guest work directory.
4. Run and inspect them inside the guest.

## Control guest applications when needed

Use the VNC endpoint printed by the retained Tart session with the globally installed `vncdo`
(`uv tool install vncdotool`), and keep VNC captures in `/private/tmp` on the host:

```console
vncdo -s 127.0.0.1::<port> -p '<password>' capture /private/tmp/tart-vm-screen.png
```

Capture before each interaction, derive coordinates from the current screen using 1:1 framebuffer
pixel coordinates (for example `2048x1536` on Retina virtual displays, not 1x logical points),
and capture again after each click or keystroke. `vncdo` Command-key combinations (`super-*`,
`meta-*`) are unreliable against Virtualization.framework's VNC server; prefer clicking UI controls
or running guest commands over `ssh`.

Open target applications inside the guest (built-in macOS apps live under `/System/Applications`):

```console
ssh <confirmed-vm-name> 'open "/Applications/<Application>.app"'
```

Do not use an unqualified host `open` command.

For guest macOS permission prompts:

1. Identify the requesting guest process, permission, and available choices from a fresh
   capture.
2. Grant only the guest permission required by the task.
3. Follow the guest System Settings flow and enter only the guest credential.
4. Rerun the guest behavior and verify the result.

Use read-only guest TCC queries when exact verification is useful. Never edit or pre-seed TCC
databases, and never grant host Accessibility, Automation, Screen Recording, Input Monitoring,
Full Disk Access, or other host permissions for a guest task.

## Finish

Send Ctrl-C to the retained Tart session, wait for `Stopping VM...`, and confirm `stopped` with
`command tart list`. Do not force-terminate a normal shutdown.
