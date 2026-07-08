#!/usr/bin/env python3
"""Tests for scripts/export_play_release_notes.py."""

from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "export_play_release_notes.py"


CATALOG = """
{
  "releases": [
    {
      "version": "1.2.3",
      "title": "Baskit 1.2.3",
      "items": [
        {
          "type": "improvement",
          "importance": "high",
          "userFacing": true,
          "group": "lists",
          "title": "Better lists",
          "description": "Lists are easier to scan."
        },
        {
          "type": "bugfix",
          "importance": "low",
          "userFacing": false,
          "group": "internal",
          "title": "Internal logging",
          "description": "Hidden from users."
        }
      ]
    },
    {
      "version": "1.2.4",
      "title": "Baskit 1.2.4",
      "items": [
        {
          "type": "bugfix",
          "importance": "medium",
          "userFacing": true,
          "group": "sharing",
          "title": "Safer sharing",
          "description": "Shared lists load more reliably."
        },
        {
          "type": "improvement",
          "importance": "medium",
          "userFacing": true,
          "group": "lists",
          "title": "Better list details",
          "description": "List cards show the newest details."
        },
        {
          "type": "improvement",
          "importance": "low",
          "userFacing": true,
          "group": "sharing",
          "title": "Safer sharing",
          "description": "Older duplicate that should be hidden."
        }
      ]
    },
    {
      "version": "1.2.5",
      "title": "Baskit 1.2.5",
      "items": [
        {
          "type": "bugfix",
          "importance": "high",
          "userFacing": true,
          "group": "lists",
          "title": "Fixed list loading",
          "description": "Lists recover after connection problems."
        }
      ]
    }
  ]
}
""".strip()


class ExportPlayReleaseNotesTest(unittest.TestCase):
    def run_export(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(SCRIPT), *args],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )

    def test_single_release_export_filters_non_user_facing_items(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            source = tmp_path / "releases.json"
            play = tmp_path / "whatsnew-en-GB"
            markdown = tmp_path / "whats-new.md"
            source.write_text(CATALOG, encoding="utf-8")

            result = self.run_export(
                "--source", str(source),
                "--version", "1.2.3",
                "--play-output", str(play),
                "--markdown-output", str(markdown),
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            notes = play.read_text(encoding="utf-8")
            self.assertIn("Better lists", notes)
            self.assertNotIn("Internal logging", notes)

    def test_cumulative_export_uses_promotion_state_and_deduplicates_exact_group_titles(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            source = tmp_path / "releases.json"
            state = tmp_path / "state.json"
            play = tmp_path / "whatsnew-en-GB"
            markdown = tmp_path / "whats-new.md"
            source.write_text(CATALOG, encoding="utf-8")
            state.write_text('{"lastUserVisibleVersion":"1.2.3"}', encoding="utf-8")

            result = self.run_export(
                "--source", str(source),
                "--version", "1.2.5",
                "--mode", "cumulative",
                "--promotion-state", str(state),
                "--play-output", str(play),
                "--markdown-output", str(markdown),
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            notes = play.read_text(encoding="utf-8")
            self.assertIn("highlights since 1.2.3", notes)
            self.assertIn("Fixed list loading", notes)
            self.assertIn("Safer sharing", notes)
            self.assertIn("Better list details", notes)
            self.assertNotIn("Older duplicate", notes)

    def test_cumulative_export_fails_for_empty_range(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            source = tmp_path / "releases.json"
            source.write_text(CATALOG, encoding="utf-8")

            result = self.run_export(
                "--source", str(source),
                "--version", "1.2.5",
                "--mode", "cumulative",
                "--since-version", "1.2.5",
                "--play-output", str(tmp_path / "play"),
                "--markdown-output", str(tmp_path / "md"),
            )

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("range is empty", result.stderr)

    def test_cumulative_export_fails_without_baseline(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            source = tmp_path / "releases.json"
            source.write_text(CATALOG, encoding="utf-8")

            result = self.run_export(
                "--source", str(source),
                "--version", "1.2.5",
                "--mode", "cumulative",
                "--promotion-state", str(tmp_path / "missing.json"),
                "--play-output", str(tmp_path / "play"),
                "--markdown-output", str(tmp_path / "md"),
            )

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("requires --since-version", result.stderr)

    def test_cumulative_export_fails_without_candidate_release_entry(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            source = tmp_path / "releases.json"
            source.write_text(CATALOG, encoding="utf-8")

            result = self.run_export(
                "--source", str(source),
                "--version", "1.2.6",
                "--mode", "cumulative",
                "--since-version", "1.2.3",
                "--play-output", str(tmp_path / "play"),
                "--markdown-output", str(tmp_path / "md"),
            )

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("No release entry found for candidate version 1.2.6", result.stderr)

    def test_play_character_limit_failure_is_actionable(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            source = tmp_path / "releases.json"
            source.write_text(CATALOG, encoding="utf-8")

            result = self.run_export(
                "--source", str(source),
                "--version", "1.2.3",
                "--max-play-chars", "20",
                "--play-output", str(tmp_path / "play"),
                "--markdown-output", str(tmp_path / "md"),
            )

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("Reduce low-importance items", result.stderr)


if __name__ == "__main__":
    unittest.main()
