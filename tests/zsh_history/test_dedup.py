"""Tests for zsh history deduplication."""

from __future__ import annotations

from pathlib import Path

import history_codec
import history_dedup


def test_preserves_japanese_text(tmp_path: Path) -> None:
    """Ensure deduplication keeps Japanese history text readable."""

    histfile = tmp_path / ".zsh_history"
    history = ": 1:0;echo 日本語\n: 2:0;echo ok\n: 3:0;echo 日本語\n"
    histfile.write_bytes(history_codec.encode_history_text(history))

    changed = history_dedup.dedup_history_file(histfile)

    decoded = history_codec.read_history_text(histfile)
    assert changed is True
    assert decoded == ": 2:0;echo ok\n: 3:0;echo 日本語\n"
    assert "�" not in decoded


def test_drops_invalid_unmetafied_entry(tmp_path: Path) -> None:
    """Ensure deduplication drops malformed entries even without duplicates."""

    histfile = tmp_path / ".zsh_history"
    valid_history = ": 1:0;echo keep\n"
    invalid_history = ": 2:0;echo テスト\n".encode()
    histfile.write_bytes(
        history_codec.encode_history_text(valid_history) + invalid_history
    )

    history_dedup.dedup_history_file(histfile)

    decoded = history_codec.read_history_text(histfile)
    assert decoded == valid_history
