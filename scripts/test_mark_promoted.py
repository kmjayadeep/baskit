#!/usr/bin/env python3
"""Tests for scripts/mark_promoted.sh."""

from __future__ import annotations

import json
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "mark_promoted.sh"


CATALOG = {
    "releases": [
        {"version": "1.2.3", "items": [{"title": "Baseline", "userFacing": True}]},
        {"version": "1.2.4", "items": [{"title": "Candidate", "userFacing": True}]},
    ]
}


class MarkPromotedTest(unittest.TestCase):
    def write_repo_files(self, root: Path, baseline: str = "1.2.3") -> None:
        releases = root / "app" / "assets" / "whats_new" / "releases.json"
        state = root / "docs" / "release-promotion-state.json"
        releases.parent.mkdir(parents=True, exist_ok=True)
        state.parent.mkdir(parents=True, exist_ok=True)
        releases.write_text(json.dumps(CATALOG), encoding="utf-8")
        state.write_text(
            json.dumps({"lastUserVisibleVersion": baseline, "track": "closed", "updatedAt": "2026-07-08"}),
            encoding="utf-8",
        )

    def run_script(self, cwd: Path, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["bash", str(SCRIPT), *args],
            cwd=cwd,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )

    def test_updates_baseline_for_newer_version(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_repo_files(root)

            result = self.run_script(root, "1.2.4", "--track", "open")

            self.assertEqual(result.returncode, 0, result.stderr)
            state = json.loads((root / "docs" / "release-promotion-state.json").read_text(encoding="utf-8"))
            self.assertEqual(state["lastUserVisibleVersion"], "1.2.4")
            self.assertEqual(state["track"], "open")

    def test_refuses_to_move_baseline_backwards_or_sideways(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_repo_files(root, baseline="1.2.4")

            result = self.run_script(root, "1.2.3", "--track", "closed")

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("Refusing to move promotion baseline", result.stderr)
            state = json.loads((root / "docs" / "release-promotion-state.json").read_text(encoding="utf-8"))
            self.assertEqual(state["lastUserVisibleVersion"], "1.2.4")

    def test_requires_track_value(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.write_repo_files(root)

            result = self.run_script(root, "1.2.4", "--track", "--unexpected")

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("--track requires one of", result.stderr)


if __name__ == "__main__":
    unittest.main()
