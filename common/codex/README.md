# Codex Tools and Configuration

This setup configures Codex CLI rules and logging. For the shared turn-diff
viewer, containers, VMs, and skills, see [common/README.md](../README.md).

## Rules

[Rules](./rules) preapprove selected safe commands to reduce the automatic
approval reviewer's token usage.

## SQLite logging

[Disable diagnostic logging](./disable_sqlite_logging.py) to reduce disk writes.
Start Codex once, quit all Codex processes, then run:

```console
python3 ~/configs/common/codex/disable_sqlite_logging.py \
    "${CODEX_SQLITE_HOME:-${CODEX_HOME:-$HOME/.codex}}/logs_2.sqlite"
```
