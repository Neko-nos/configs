"""Tests for Codex VS Code extension root updates."""

import os
import sys
from pathlib import Path

import pytest

sys.path.append(str(Path(__file__).resolve().parents[2] / "common" / "codex"))

import update_vscode_extension_root  # noqa: E402


def test_update_config_text_replaces_extension_version() -> None:
    """Ensure only the VS Code extension root is replaced."""
    config_text = """
[permissions.workspace_with_secret_denies.filesystem]
"~/.vscode-server/extensions/openai.chatgpt-1.2.3-linux-x64" = "read"
"~/.cache/uv" = "write"
"""

    updated_text, changed = update_vscode_extension_root.update_config_text(
        config_text,
        "~/.vscode-server/extensions/openai.chatgpt-1.2.3-linux-x64",
        "openai.chatgpt-2.0.0-linux-x64",
    )

    assert changed is True
    assert "openai.chatgpt-1.2.3-linux-x64" not in updated_text
    assert "openai.chatgpt-2.0.0-linux-x64" in updated_text
    assert '"~/.cache/uv" = "write"' in updated_text


def test_update_config_text_keeps_matching_config_unchanged() -> None:
    """Ensure matching config text is left untouched."""
    config_text = '"~/.vscode-server/extensions/openai.chatgpt-2.0.0-linux-x64",\n'

    updated_text, changed = update_vscode_extension_root.update_config_text(
        config_text,
        "~/.vscode-server/extensions/openai.chatgpt-2.0.0-linux-x64",
        "openai.chatgpt-2.0.0-linux-x64",
    )

    assert changed is False
    assert updated_text == config_text


def test_find_latest_extension_dir_uses_numeric_version(tmp_path: Path) -> None:
    """Ensure numeric version ordering is used instead of lexical ordering."""
    older = tmp_path / "openai.chatgpt-9.0.0-linux-x64"
    newer = tmp_path / "openai.chatgpt-10.0.0-linux-x64"
    unrelated = tmp_path / "publisher.other-99.0.0-linux-x64"
    older.mkdir()
    newer.mkdir()
    unrelated.mkdir()

    latest = update_vscode_extension_root.find_latest_extension_dir(tmp_path)

    assert latest == newer


def test_cached_run_updates_when_configured_root_is_missing(
    tmp_path: Path,
    monkeypatch,
    capsys,
) -> None:
    """Ensure a fresh stamp does not hide a stale extension root."""
    config_path = tmp_path / "config.toml"
    extension_root = tmp_path / ".vscode-server" / "extensions"
    stamp_path = tmp_path / "stamp"
    extension_root.mkdir(parents=True)
    (extension_root / "openai.chatgpt-2.0.0-linux-x64").mkdir(parents=True)
    config_path.write_text(
        '"~/.vscode-server/extensions/openai.chatgpt-1.0.0-linux-x64"\n'
    )
    stamp_path.touch()
    os.utime(stamp_path, None)

    monkeypatch.setattr(
        sys,
        "argv",
        [
            "update_vscode_extension_root.py",
            "--config",
            str(config_path),
            "-f",
            "--stamp",
            str(stamp_path),
        ],
    )
    monkeypatch.setenv("HOME", str(tmp_path))

    assert update_vscode_extension_root.main() == 0
    captured = capsys.readouterr()
    assert "openai.chatgpt-2.0.0-linux-x64" in config_path.read_text()
    assert "Updated Codex VS Code extension root: 1.0.0 -> 2.0.0" in captured.out


def test_warns_when_no_extension_is_installed(
    tmp_path: Path,
    monkeypatch,
) -> None:
    """Ensure missing installed extensions are visible to the user."""
    config_path = tmp_path / "config.toml"
    stamp_path = tmp_path / "stamp"
    config_path.write_text(
        '"~/.vscode-server/extensions/openai.chatgpt-1.0.0-linux-x64"\n'
    )

    monkeypatch.setattr(
        sys,
        "argv",
        [
            "update_vscode_extension_root.py",
            "--config",
            str(config_path),
            "--stamp",
            str(stamp_path),
        ],
    )
    monkeypatch.setenv("HOME", str(tmp_path))

    with pytest.warns(UserWarning, match="No Codex VS Code extension found in"):
        assert update_vscode_extension_root.main() == 0
