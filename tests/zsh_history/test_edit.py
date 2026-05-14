"""Tests for editing zsh history through normal editors."""

from __future__ import annotations

import io
import os
import sys
from pathlib import Path

import history_codec
import history_edit
import pytest


def test_select_editor_uses_explicit_editor_before_environment() -> None:
    """Ensure an explicit editor overrides environment variables."""

    editor = history_edit._select_editor_command(
        "custom-editor --wait",
        {"EDITOR": "env-editor", "VISUAL": "visual-editor"},
    )

    assert editor == ["custom-editor", "--wait"]


def test_select_editor_uses_visual_before_editor() -> None:
    """Ensure VISUAL is preferred over EDITOR."""

    editor = history_edit._select_editor_command(
        None,
        {"EDITOR": "env-editor", "VISUAL": "visual-editor"},
    )

    assert editor == ["visual-editor"]


def test_select_editor_uses_editor_when_visual_is_unset() -> None:
    """Ensure EDITOR is used when VISUAL is unset."""

    editor = history_edit._select_editor_command(
        None,
        {"EDITOR": "env-editor --wait"},
    )

    assert editor == ["env-editor", "--wait"]


def test_select_editor_requires_editor_configuration() -> None:
    """Ensure no editor is guessed without explicit configuration."""

    with pytest.raises(history_edit.HistoryEditError, match="set VISUAL or EDITOR"):
        history_edit._select_editor_command(None, {})


def test_merges_append_added_while_editor_is_open(
    monkeypatch,
    tmp_path: Path,
) -> None:
    """Ensure editor-time external appends are preserved at the end."""

    histfile = tmp_path / ".zsh_history"
    initial_history = ": 1:0;echo base\n"
    external_history = ": 2:0;echo 外部\n"
    histfile.write_bytes(history_codec.encode_history_text(initial_history))

    editor_script = tmp_path / "editor.py"
    editor_script.write_text(
        "\n".join(
            [
                "from pathlib import Path",
                "import os",
                "import sys",
                "edit_path = Path(sys.argv[1])",
                "edit_path.write_text(",
                "    edit_path.read_text(encoding='utf-8') + ': 3:0;echo edited\\n',",
                "    encoding='utf-8',",
                ")",
                "histfile = Path(os.environ['TARGET_HISTFILE'])",
                "histfile.write_bytes(",
                "    histfile.read_bytes() + bytes.fromhex(os.environ['APPEND_HEX'])",
                ")",
            ],
        ),
        encoding="utf-8",
    )
    monkeypatch.setenv("TARGET_HISTFILE", os.fspath(histfile))
    monkeypatch.setenv(
        "APPEND_HEX",
        history_codec.encode_history_text(external_history).hex(),
    )

    stdout = io.StringIO()
    result = history_edit.edit_history_file(
        histfile,
        [sys.executable, str(editor_script)],
        stdout=stdout,
    )

    assert result.editor_append_count == 1
    assert result.save_append_count == 0
    assert "while the editor was open" in stdout.getvalue()
    assert history_codec.read_history_text(histfile) == (
        initial_history + ": 3:0;echo edited\n" + external_history
    )


def test_merges_append_added_during_save(tmp_path: Path) -> None:
    """Ensure save-time external appends are preserved at the end."""

    histfile = tmp_path / ".zsh_history"
    initial_history = ": 1:0;echo base\n"
    external_history = ": 2:0;echo save-time\n"
    base_bytes = history_codec.encode_history_text(initial_history)
    histfile.write_bytes(
        base_bytes + history_codec.encode_history_text(external_history)
    )

    count, _ = history_edit._write_merged_history(
        histfile=histfile,
        edited_text=initial_history + ": 3:0;echo edited\n",
        known_bytes=base_bytes,
    )

    assert count == 1
    assert history_codec.read_history_text(histfile) == (
        initial_history + ": 3:0;echo edited\n" + external_history
    )


def test_saves_editor_work_when_post_edit_merge_aborts(
    monkeypatch,
    tmp_path: Path,
) -> None:
    """Ensure edited content is saved when merging aborts after editor work."""

    monkeypatch.setenv("HOME", os.fspath(tmp_path))
    histfile = tmp_path / ".zsh_history"
    initial_history = ": 1:0;echo base\n: 2:0;echo removed externally\n"
    rewritten_history = ": 1:0;echo base\n"
    edited_history = initial_history + ": 3:0;echo edited\n"
    histfile.write_bytes(history_codec.encode_history_text(initial_history))

    editor_script = tmp_path / "editor.py"
    editor_script.write_text(
        "\n".join(
            [
                "from pathlib import Path",
                "import os",
                "import sys",
                "edit_path = Path(sys.argv[1])",
                "edit_path.write_text(",
                "    edit_path.read_text(encoding='utf-8') + ': 3:0;echo edited\\n',",
                "    encoding='utf-8',",
                ")",
                "Path(os.environ['TARGET_HISTFILE']).write_bytes(",
                "    bytes.fromhex(os.environ['REWRITTEN_HEX'])",
                ")",
            ],
        ),
        encoding="utf-8",
    )
    monkeypatch.setenv("TARGET_HISTFILE", os.fspath(histfile))
    monkeypatch.setenv(
        "REWRITTEN_HEX",
        history_codec.encode_history_text(rewritten_history).hex(),
    )

    with pytest.raises(history_edit.HistoryEditError, match="edited history was saved"):
        history_edit.edit_history_file(histfile, [sys.executable, str(editor_script)])

    saved_files = sorted(tmp_path.glob("zsh-history-edit-abort-edited-*.txt"))
    assert len(saved_files) == 1
    assert saved_files[0].read_text(encoding="utf-8") == edited_history


def test_does_not_save_editor_work_for_pre_editor_abort(
    monkeypatch,
    tmp_path: Path,
) -> None:
    """Ensure no editor work file is saved when aborting before editor launch."""

    monkeypatch.setenv("HOME", os.fspath(tmp_path))
    histfile = tmp_path / ".zsh_history"
    valid_history = ": 1:0;echo keep\n"
    histfile.write_bytes(
        history_codec.encode_history_text(valid_history) + b": 2:0;echo bad\x83"
    )

    with pytest.raises(history_edit.HistoryEditError, match="history contains"):
        history_edit.edit_history_file(histfile, [sys.executable, "-c", ""])

    assert list(tmp_path.glob("zsh-history-edit-abort-edited-*.txt")) == []
