"""Shared test setup for turn-diff hooks."""

from __future__ import annotations

import sys
from pathlib import Path

TURN_DIFF_DIR = Path(__file__).resolve().parents[2] / "common" / "hooks" / "turn-diff"
sys.path.append(str(TURN_DIFF_DIR))
