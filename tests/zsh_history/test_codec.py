"""Tests for zsh history metafication handling."""

from __future__ import annotations

import fcntl
from pathlib import Path

import history_codec


def test_round_trips_japanese_text(tmp_path: Path, read_locked_text) -> None:
    """Ensure Japanese history text round-trips through zsh metafication."""

    histfile = tmp_path / ".zsh_history"
    text = ": 1:0;echo 日本語\n"

    encoded = history_codec.encode_history_text(text)
    histfile.write_bytes(encoded)

    assert encoded != text.encode()
    assert read_locked_text(histfile) == text


def test_drops_incomplete_meta_pair_entry(tmp_path: Path, read_locked_text) -> None:
    """Ensure malformed zsh metafied entries are dropped."""

    histfile = tmp_path / ".zsh_history"
    encoded = b": 1:0;echo " + bytes([history_codec.META])
    histfile.write_bytes(encoded)

    assert read_locked_text(histfile) == ""
    assert histfile.read_bytes() == b""


def test_locked_history_file_takes_exclusive_lock(
    monkeypatch,
    tmp_path: Path,
) -> None:
    """Ensure the shared history file lock uses an exclusive fcntl lock."""

    histfile = tmp_path / ".zsh_history"
    calls: list[int] = []

    def record_lock(_file_descriptor: int, flags: int) -> None:
        calls.append(flags)

    monkeypatch.setattr(history_codec.fcntl, "lockf", record_lock)

    with history_codec.locked_history_file(histfile):
        pass

    assert calls == [fcntl.LOCK_EX]


def test_locked_history_text_helpers_round_trip(
    tmp_path: Path,
    read_locked_text,
) -> None:
    """Ensure locked text helpers read and replace encoded history."""

    histfile = tmp_path / ".zsh_history"
    initial_text = ": 1:0;echo before\n"
    updated_text = ": 2:0;echo after\n"
    histfile.write_bytes(history_codec.encode_history_text(initial_text))

    with history_codec.locked_history_file(histfile) as history_file:
        assert history_codec.read_locked_history_text(history_file) == initial_text
        history_codec.write_locked_history_text(history_file, updated_text)

    assert read_locked_text(histfile) == updated_text
