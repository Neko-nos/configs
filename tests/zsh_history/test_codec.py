"""Tests for zsh history metafication handling."""

from __future__ import annotations

from pathlib import Path

import history_codec


def test_round_trips_japanese_text(tmp_path: Path) -> None:
    """Ensure Japanese history text round-trips through zsh metafication."""

    histfile = tmp_path / ".zsh_history"
    text = ": 1:0;echo 日本語\n"

    encoded = history_codec.encode_history_text(text)
    histfile.write_bytes(encoded)

    assert encoded != text.encode()
    assert history_codec.read_history_text(histfile) == text


def test_drops_incomplete_meta_pair_entry(tmp_path: Path) -> None:
    """Ensure malformed zsh metafied entries are dropped."""

    histfile = tmp_path / ".zsh_history"
    encoded = b": 1:0;echo " + bytes([history_codec.META])
    histfile.write_bytes(encoded)

    assert history_codec.read_history_text(histfile) == ""
    assert histfile.read_bytes() == b""
