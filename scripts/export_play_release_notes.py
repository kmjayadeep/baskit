#!/usr/bin/env python3
"""Export Baskit What's New JSON into Google Play release-note files."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


def _load_release_notes(source: Path) -> dict[str, Any]:
    try:
        data = json.loads(source.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise SystemExit(f"Release notes source not found: {source}") from exc
    except json.JSONDecodeError as exc:
        raise SystemExit(f"Invalid JSON in {source}: {exc}") from exc

    if not isinstance(data, dict):
        raise SystemExit(f"Expected {source} to contain a JSON object")

    version = data.get("version")
    title = data.get("title")
    items = data.get("items")

    if not isinstance(version, str) or not version.strip():
        raise SystemExit(f"{source} must contain a non-empty string 'version'")
    if title is not None and not isinstance(title, str):
        raise SystemExit(f"{source} field 'title' must be a string when present")
    if not isinstance(items, list) or not items:
        raise SystemExit(f"{source} must contain a non-empty 'items' array")

    for index, item in enumerate(items, start=1):
        if not isinstance(item, dict):
            raise SystemExit(f"{source} item {index} must be a JSON object")
        item_title = item.get("title")
        if not isinstance(item_title, str) or not item_title.strip():
            raise SystemExit(f"{source} item {index} must contain a non-empty string 'title'")
        description = item.get("description", "")
        if description is not None and not isinstance(description, str):
            raise SystemExit(f"{source} item {index} field 'description' must be a string")

    return data


def _render_play_notes(data: dict[str, Any]) -> str:
    heading = (data.get("title") or f"Baskit {data['version']}").strip()
    lines = [heading]

    for item in data["items"]:
        title = item["title"].strip()
        description = (item.get("description") or "").strip()
        if description:
            lines.append(f"- {title}: {description}")
        else:
            lines.append(f"- {title}")

    return "\n".join(lines).strip() + "\n"


def _render_markdown_notes(data: dict[str, Any]) -> str:
    heading = (data.get("title") or f"Baskit {data['version']}").strip()
    lines = [f"# {heading}", "", f"Version: `{data['version']}`", ""]

    for item in data["items"]:
        item_type = (item.get("type") or "change").strip()
        title = item["title"].strip()
        description = (item.get("description") or "").strip()
        lines.append(f"- **{title}** ({item_type})")
        if description:
            lines.append(f"  {description}")

    return "\n".join(lines).strip() + "\n"


def _write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Convert app/assets/whats_new/latest.json into Google Play and "
            "archive-friendly release notes."
        )
    )
    parser.add_argument(
        "--source",
        type=Path,
        default=Path("app/assets/whats_new/latest.json"),
        help="Baskit What's New JSON file to export.",
    )
    parser.add_argument(
        "--play-output",
        type=Path,
        default=Path("release-artifacts/release-notes/play/en-US/default.txt"),
        help="Google Play whatsNewDirectory locale file to write.",
    )
    parser.add_argument(
        "--markdown-output",
        type=Path,
        default=Path("release-artifacts/release-notes/whats-new.md"),
        help="Markdown release note artifact to write.",
    )
    parser.add_argument(
        "--max-play-chars",
        type=int,
        default=500,
        help="Maximum Google Play release-note length per locale.",
    )
    args = parser.parse_args()

    data = _load_release_notes(args.source)
    play_notes = _render_play_notes(data)
    if len(play_notes) > args.max_play_chars:
        raise SystemExit(
            f"Rendered Play release notes are {len(play_notes)} characters; "
            f"maximum is {args.max_play_chars}. Shorten {args.source}."
        )

    markdown_notes = _render_markdown_notes(data)
    _write(args.play_output, play_notes)
    _write(args.markdown_output, markdown_notes)

    print(f"Wrote Play release notes: {args.play_output} ({len(play_notes)} chars)")
    print(f"Wrote Markdown release notes: {args.markdown_output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
