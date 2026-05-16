"""Tests for zsh history pruning."""

from __future__ import annotations

from pathlib import Path

import history_codec
import history_prune


def test_preserves_japanese_text(tmp_path: Path, read_locked_text) -> None:
    """Ensure pruning keeps Japanese history text readable."""

    histfile = tmp_path / ".zsh_history"
    history = ": 1:0;echo 日本語\n: 2:0;echo ok\n: 3:0;echo 日本語\n"
    histfile.write_bytes(history_codec.encode_history_text(history))

    changed = history_prune.prune_history_file(histfile, "echo ok")

    decoded = read_locked_text(histfile)
    assert changed is True
    assert decoded == ": 1:0;echo 日本語\n: 3:0;echo 日本語\n"
    assert "�" not in decoded


def test_drops_invalid_unmetafied_entry_without_match(
    tmp_path: Path,
    read_locked_text,
) -> None:
    """Ensure pruning drops malformed entries even when no command matches."""

    histfile = tmp_path / ".zsh_history"
    valid_history = ": 1:0;echo keep\n"
    invalid_history = ": 2:0;echo テスト\n".encode()
    histfile.write_bytes(
        history_codec.encode_history_text(valid_history) + invalid_history
    )

    history_prune.prune_history_file(histfile, "echo missing")

    decoded = read_locked_text(histfile)
    assert decoded == valid_history
