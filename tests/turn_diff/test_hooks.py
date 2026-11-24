"""Tests for shared Codex and Antigravity turn-diff hooks."""

from __future__ import annotations

import json
import os
import stat
import subprocess
from pathlib import Path

import hook_context
import prune_turns
import turn_store

TURN_DIFF_DIR = Path(__file__).resolve().parents[2] / "common" / "hooks" / "turn-diff"


def _init_repo(repo: Path) -> None:
    """
    Create a Git repository with one initial commit.

    Args:
        repo (Path): Target repository directory.
    """
    repo.mkdir(parents=True, exist_ok=True)
    subprocess.run(["git", "init", "-q"], cwd=repo, check=True)
    subprocess.run(["git", "config", "user.email", "test"], cwd=repo, check=True)
    subprocess.run(["git", "config", "user.name", "Test"], cwd=repo, check=True)
    (repo / "sample.py").write_text("x = 1\n", encoding="utf-8")
    subprocess.run(["git", "add", "."], cwd=repo, check=True)
    subprocess.run(["git", "commit", "-q", "-m", "init"], cwd=repo, check=True)


def _install_fake_tmux(tmp_path: Path) -> tuple[dict[str, str], Path]:
    """
    Install a stub `tmux` executable that records copied clipboard commands.

    Args:
        tmp_path (Path): Temporary directory for the stub binary and capture file.

    Returns:
        tuple[dict[str, str], Path]: Environment overrides and capture log path.
    """
    bin_dir = tmp_path / "fake-bin"
    bin_dir.mkdir(exist_ok=True)
    capture_file = tmp_path / "copied-command.txt"
    tmux_script = bin_dir / "tmux"
    tmux_script.write_text(
        "#!/bin/sh\n"
        'if [ "$1" = "display-message" ]; then\n'
        '    printf "/dev/ttys001\\n"\n'
        "    exit 0\n"
        "fi\n"
        'if [ "$1" = "set-buffer" ]; then\n'
        f'    printf "%s" "$6" > "{capture_file}"\n'
        "    exit 0\n"
        "fi\n"
        "exit 1\n",
        encoding="utf-8",
    )
    tmux_script.chmod(tmux_script.stat().st_mode | stat.S_IEXEC)
    env = {
        "PATH": f"{bin_dir}:{os.environ['PATH']}",
        "SSH_TTY": "/dev/ttys001",
    }
    return env, capture_file


def _run_hook(
    script_name: str,
    payload: dict[str, object] | str,
    extra_args: list[str] | None = None,
    extra_env: dict[str, str] | None = None,
) -> subprocess.CompletedProcess[str]:
    """
    Execute a turn-diff hook script with JSON stdin.

    Args:
        script_name (str): Hook Python filename under `common/hooks/turn-diff`.
        payload (dict[str, object] | str): Hook input JSON payload or raw stdin text.
        extra_args (list[str] | None): Optional CLI arguments.
        extra_env (dict[str, str] | None): Optional extra environment variables.

    Returns:
        subprocess.CompletedProcess[str]: Completed hook process.
    """
    env = os.environ.copy()
    if extra_env:
        env.update(extra_env)
    stdin_text = payload if isinstance(payload, str) else json.dumps(payload)
    return subprocess.run(
        [
            "uv",
            "run",
            "--offline",
            "--project",
            str(TURN_DIFF_DIR),
            str(TURN_DIFF_DIR / script_name),
            *(extra_args or []),
        ],
        input=stdin_text,
        text=True,
        capture_output=True,
        env=env,
        check=True,
    )


def test_antigravity_cli_turn_lifecycle(tmp_path: Path) -> None:
    """Verify Antigravity PreInvocation, Stop, and statusLine save and report a turn."""
    repo = tmp_path / "repo"
    _init_repo(repo)
    extra_env, capture_file = _install_fake_tmux(tmp_path)
    transcript = (
        tmp_path
        / ".gemini"
        / "antigravity-cli"
        / "brain"
        / "conv-1"
        / ".system_generated"
        / "logs"
        / "transcript.jsonl"
    )
    transcript.parent.mkdir(parents=True)

    pre_step_0 = {
        "hookEventName": "PreInvocation",
        "conversationId": "conv-1",
        "cwd": str(repo),
        "transcriptPath": str(transcript),
        "invocationNum": 0,
    }
    res0 = _run_hook("capture_turn.py", pre_step_0)
    assert json.loads(res0.stdout) == {}

    session_dir = repo / ".git" / "turn-diff" / "conv-1"
    active_turn_file = session_dir / hook_context.ACTIVE_TURN_FILE
    status_file = session_dir / hook_context.STATUS_FILE
    turn_id = active_turn_file.read_text(encoding="utf-8").strip()
    assert (session_dir / turn_id / "state.json").is_file()
    assert not status_file.exists()

    # Second model invocation in the same turn preserves the original baseline.
    (repo / "sample.py").write_text("x = 2\n", encoding="utf-8")
    pre_step_1 = {**pre_step_0, "invocationNum": 1}
    res1 = _run_hook("capture_turn.py", pre_step_1)
    assert json.loads(res1.stdout) == {}
    assert active_turn_file.read_text(encoding="utf-8").strip() == turn_id

    # Edit again before Stop; Stop saves the turn diff and records the status line message.
    (repo / "sample.py").write_text("x = 3\n", encoding="utf-8")
    stop_payload = {
        "hookEventName": "Stop",
        "conversationId": "conv-1",
        "cwd": str(repo),
        "transcriptPath": str(transcript),
        "fullyIdle": True,
    }
    stop_res = _run_hook("save_turn.py", stop_payload, extra_env=extra_env)
    assert json.loads(stop_res.stdout) == {"decision": "allow"}
    assert not active_turn_file.exists()
    assert (
        status_file.read_text(encoding="utf-8")
        == "Turn diff: viewer command sent to clipboard."
    )

    # Status line hides the message while working and shows it when idle.
    status_payload = {
        "conversation_id": "conv-1",
        "cwd": str(repo),
        "agent_state": "working",
    }
    assert _run_hook("status_line.py", status_payload).stdout == ""
    idle_res = _run_hook("status_line.py", {**status_payload, "agent_state": "idle"})
    assert idle_res.stdout.strip() == "Turn diff: viewer command sent to clipboard."

    # Also supports workspace fallback when cwd is omitted.
    workspace_res = _run_hook(
        "status_line.py",
        {
            "session_id": "conv-1",
            "workspace": {"current_dir": str(repo)},
            "agent_state": "idle",
        },
    )
    assert (
        workspace_res.stdout.strip() == "Turn diff: viewer command sent to clipboard."
    )

    copied = capture_file.read_text(encoding="utf-8")
    assert "common/hooks/turn-diff/terminal_diff_viewer.py" in copied

    manifest_path = session_dir / turn_id / "last-turn.json"
    assert manifest_path.is_file()
    assert turn_store.apply_turn(manifest_path, reverse=True) == "Turn changes undone."
    assert (repo / "sample.py").read_text(encoding="utf-8") == "x = 1\n"
    assert (
        turn_store.apply_turn(manifest_path, reverse=False) == "Turn changes applied."
    )
    assert (repo / "sample.py").read_text(encoding="utf-8") == "x = 3\n"

    # A second turn clears the previous status message and reports no-change turns cleanly.
    pre_turn_2 = {**pre_step_0, "invocationNum": 2}
    assert json.loads(_run_hook("capture_turn.py", pre_turn_2).stdout) == {}
    turn_2_id = active_turn_file.read_text(encoding="utf-8").strip()
    assert turn_2_id != turn_id
    assert not status_file.exists()
    assert (
        _run_hook("status_line.py", {**status_payload, "agent_state": "idle"}).stdout
        == ""
    )

    stop_turn_2 = _run_hook("save_turn.py", stop_payload, extra_env=extra_env)
    assert json.loads(stop_turn_2.stdout) == {"decision": "allow"}
    assert (
        _run_hook(
            "status_line.py", {**status_payload, "agent_state": "idle"}
        ).stdout.strip()
        == "Turn diff: no file changes."
    )


def test_status_line_handles_missing_and_invalid_inputs_gracefully(
    tmp_path: Path,
) -> None:
    """Verify status_line.py always exits 0 with empty output on unusable inputs."""
    non_git_dir = tmp_path / "plain"
    non_git_dir.mkdir()
    for payload in (
        "not-json",
        {},
        {"conversation_id": "", "cwd": str(non_git_dir), "agent_state": "idle"},
        {
            "conversation_id": "../escape",
            "cwd": str(non_git_dir),
            "agent_state": "idle",
        },
        {"conversation_id": "conv-1", "cwd": str(non_git_dir), "agent_state": "idle"},
        {
            "conversation_id": "conv-1",
            "cwd": str(tmp_path / "missing"),
            "agent_state": "idle",
        },
    ):
        res = _run_hook("status_line.py", payload)
        assert res.stdout == ""


def test_antigravity_non_cli_returns_valid_json_without_side_effects(
    tmp_path: Path,
) -> None:
    """Verify Antigravity App/IDE sessions no-op while emitting valid JSON."""
    repo = tmp_path / "repo"
    _init_repo(repo)
    app_transcript = (
        tmp_path
        / ".gemini"
        / "antigravity"
        / "brain"
        / "conv-app"
        / ".system_generated"
        / "logs"
        / "transcript.jsonl"
    )
    base_payload = {
        "conversationId": "conv-app",
        "workspacePaths": [str(repo)],
        "transcriptPath": str(app_transcript),
    }

    assert (
        json.loads(
            _run_hook(
                "prune_turns.py", {**base_payload, "hookEventName": "SessionStart"}
            ).stdout
        )
        == {}
    )
    assert (
        json.loads(
            _run_hook(
                "capture_turn.py", {**base_payload, "hookEventName": "PreInvocation"}
            ).stdout
        )
        == {}
    )
    assert json.loads(
        _run_hook("save_turn.py", {**base_payload, "hookEventName": "Stop"}).stdout
    ) == {"decision": "allow"}
    assert not (repo / ".git" / "turn-diff").exists()


def test_antigravity_session_start_prunes_stale_sessions(tmp_path: Path) -> None:
    """Verify Antigravity SessionStart prunes stale sessions using workspacePaths."""
    repo = tmp_path / "repo"
    _init_repo(repo)
    stale_dir = repo / ".git" / "turn-diff" / "stale-session"
    stale_dir.mkdir(parents=True)
    stale_file = stale_dir / "marker"
    stale_file.write_text("old", encoding="utf-8")
    old_time = 1_000_000_000
    os.utime(stale_file, (old_time, old_time))
    os.utime(stale_dir, (old_time, old_time))

    transcript = (
        tmp_path
        / ".gemini"
        / "antigravity-cli"
        / "brain"
        / "fresh-session"
        / "transcript.jsonl"
    )
    payload = {
        "hookEventName": "SessionStart",
        "conversationId": "fresh-session",
        "workspacePaths": [str(repo)],
        "transcriptPath": str(transcript),
    }
    res = _run_hook("prune_turns.py", payload, extra_args=["--retention-days", "30"])
    assert json.loads(res.stdout) == {}
    assert not stale_dir.exists()


def test_codex_cli_turn_lifecycle(tmp_path: Path) -> None:
    """Verify Codex hook payloads keep working with the shared scripts."""
    repo = tmp_path / "repo"
    _init_repo(repo)
    extra_env, capture_file = _install_fake_tmux(tmp_path)
    transcript = tmp_path / "codex-transcript.jsonl"
    transcript.write_text(
        json.dumps({"payload": {"originator": "codex-tui"}}) + "\n",
        encoding="utf-8",
    )
    payload = {
        "session_id": "codex-session",
        "turn_id": "turn-1",
        "transcript_path": str(transcript),
        "cwd": str(repo),
    }

    cap = _run_hook("capture_turn.py", payload)
    assert cap.stdout == ""

    (repo / "sample.py").write_text("x = 42\n", encoding="utf-8")
    stop_res = _run_hook("save_turn.py", payload, extra_env=extra_env)
    assert json.loads(stop_res.stdout) == {
        "continue": True,
        "systemMessage": "Turn diff: viewer command sent to clipboard.",
    }
    assert "common/hooks/turn-diff/terminal_diff_viewer.py" in capture_file.read_text(
        encoding="utf-8"
    )
    assert (
        repo / ".git" / "turn-diff" / "codex-session" / "turn-1" / "last-turn.json"
    ).is_file()


def test_prune_preserves_current_session(tmp_path: Path) -> None:
    """Verify prune_diff_sessions never deletes the active session directory."""
    cache_dir = tmp_path / "turn-diff"
    current = cache_dir / "current-session"
    current.mkdir(parents=True)
    old_time = 1_000_000_000
    os.utime(current, (old_time, old_time))

    prune_turns.prune_diff_sessions(current, retention_days=1)
    assert current.exists()
