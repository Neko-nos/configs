"""Shared test setup for zsh history helpers."""

from __future__ import annotations

import sys
from collections.abc import Callable
from pathlib import Path

import pytest

ZSH_DIR = Path(__file__).resolve().parents[2] / "common" / "zsh"
sys.path.append(str(ZSH_DIR))

import history_codec  # noqa: E402


@pytest.fixture
def read_locked_text() -> Callable[[Path], str]:
    """Return a helper that reads history text through the production lock."""

    def read_text(histfile: Path) -> str:
        with history_codec.locked_history_file(histfile) as history_file:
            return history_codec.read_locked_history_text(history_file)

    return read_text
