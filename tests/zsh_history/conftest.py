"""Shared test setup for zsh history helpers."""

from __future__ import annotations

import sys
from pathlib import Path

ZSH_DIR = Path(__file__).resolve().parents[2] / "common" / "zsh"
sys.path.append(str(ZSH_DIR))
