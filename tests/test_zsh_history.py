"""Tests for zsh history metafication handling."""

from __future__ import annotations

import importlib
import sys
from pathlib import Path

import pytest

ZSH_DIR = Path(__file__).resolve().parents[1] / "common" / "zsh"
sys.path.append(str(ZSH_DIR))

history_codec = importlib.import_module("history_codec")
history_dedup = importlib.import_module("history_dedup")
history_prune = importlib.import_module("history_prune")


def test_zsh_history_codec_round_trips_japanese_text() -> None:
    """Ensure Japanese history text round-trips through zsh metafication."""

    text = ": 1:0;echo 日本語\n"

    encoded = history_codec.encode_history_text(text)

    assert encoded != text.encode()
    assert history_codec.decode_history_bytes(encoded) == text


def test_zsh_history_codec_rejects_incomplete_meta_pair() -> None:
    """Ensure malformed zsh metafied bytes are rejected."""

    encoded = b": 1:0;echo " + bytes([history_codec.META])

    with pytest.raises(ValueError, match="meta marker"):
        history_codec.decode_history_bytes(encoded)


def test_dedup_preserves_japanese_text(tmp_path: Path) -> None:
    """Ensure deduplication keeps Japanese history text readable."""

    histfile = tmp_path / ".zsh_history"
    history = ": 1:0;echo 日本語\n: 2:0;echo ok\n: 3:0;echo 日本語\n"
    histfile.write_bytes(history_codec.encode_history_text(history))

    changed = history_dedup.dedup_history_file(histfile)

    decoded = history_codec.read_history_text(histfile)
    assert changed is True
    assert decoded == ": 2:0;echo ok\n: 3:0;echo 日本語\n"
    assert "�" not in decoded


def test_prune_preserves_japanese_text(tmp_path: Path) -> None:
    """Ensure pruning keeps Japanese history text readable."""

    histfile = tmp_path / ".zsh_history"
    history = ": 1:0;echo 日本語\n: 2:0;echo ok\n: 3:0;echo 日本語\n"
    histfile.write_bytes(history_codec.encode_history_text(history))

    changed = history_prune.prune_history_file(histfile, "echo ok")

    decoded = history_codec.read_history_text(histfile)
    assert changed is True
    assert decoded == ": 1:0;echo 日本語\n: 3:0;echo 日本語\n"
    assert "�" not in decoded
