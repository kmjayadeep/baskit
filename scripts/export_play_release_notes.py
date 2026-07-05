#!/usr/bin/env python3
"""Export Baskit curated What's New releases into Google Play notes."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any


ReleaseData = dict[str, Any]


def _load_json(source: Path) -> dict[str, Any]:
    try:
        data = json.loads(source.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise SystemExit(f"Release notes source not found: {source}") from exc
    except json.JSONDecodeError as exc:
        raise SystemExit(f"Invalid JSON in {source}: {exc}") from exc

    if not isinstance(data, dict):
        raise SystemExit(f"Expected {source} to contain a JSON object")
    return data


def _read_pubspec_version(pubspec: Path) -> str:
    try:
        content = pubspec.read_text(encoding="utf-8")
    except FileNotFoundError as exc:
        raise SystemExit(f"pubspec file not found: {pubspec}") from exc

    match = re.search(r"^version:\s*([^\s+]+)(?:\+\S+)?\s*$", content, re.MULTILINE)
    if not match:
        raise SystemExit(f"Could not find a semantic version in {pubspec}")
    return match.group(1)


def _validate_item(source: Path, item: Any, index: int) -> ReleaseData:
    if not isinstance(item, dict):
        raise SystemExit(f"{source} item {index} must be a JSON object")
    title = item.get("title")
    if not isinstance(title, str) or not title.strip():
        raise SystemExit(f"{source} item {index} must contain a non-empty string 'title'")
    description = item.get("description", "")
    if description is not None and not isinstance(description, str):
        raise SystemExit(f"{source} item {index} field 'description' must be a string")
    item_type = item.get("type", "change")
    if item_type is not None and not isinstance(item_type, str):
        raise SystemExit(f"{source} item {index} field 'type' must be a string")
    return item


def _normalize_release(source: Path, release: Any, version: str | None = None) -> ReleaseData:
    if not isinstance(release, dict):
        raise SystemExit(f"Expected release entry in {source} to be a JSON object")

    release_version = release.get("version")
    title = release.get("title")
    items = release.get("items")

    if not isinstance(release_version, str) or not release_version.strip():
        raise SystemExit(f"{source} release must contain a non-empty string 'version'")
    if version is not None and release_version != version:
        raise SystemExit(
            f"Selected release version {release_version} does not match requested version {version}"
        )
    if title is not None and not isinstance(title, str):
        raise SystemExit(f"{source} field 'title' must be a string when present")
    if not isinstance(items, list):
        raise SystemExit(f"{source} release {release_version} must contain an 'items' array")

    eligible_items = []
    for index, item in enumerate(items, start=1):
        validated_item = _validate_item(source, item, index)
        if validated_item.get("userFacing", True) is True:
            eligible_items.append(validated_item)
    if not eligible_items:
        raise SystemExit(
            f"{source} release {release_version} has no userFacing=true items to export"
        )

    return {
        "version": release_version,
        "title": title or f"Baskit {release_version}",
        "items": eligible_items,
    }


def _select_release(data: dict[str, Any], source: Path, version: str | None) -> ReleaseData:
    if isinstance(data.get("releases"), list):
        if not version:
            raise SystemExit(
                "A --version value or readable --pubspec is required when exporting releases.json"
            )
        matches = [release for release in data["releases"] if release.get("version") == version]
        if not matches:
            raise SystemExit(f"No release entry found for version {version} in {source}")
        return _normalize_release(source, matches[-1], version)

    # Backward-compatible support for the old latest.json shape.
    return _normalize_release(source, data, version)


def _render_play_notes(data: ReleaseData) -> str:
    heading = str(data["title"]).strip()
    lines = [heading]

    for item in data["items"]:
        title = item["title"].strip()
        description = (item.get("description") or "").strip()
        if description:
            lines.append(f"- {title}: {description}")
        else:
            lines.append(f"- {title}")

    return "\n".join(lines).strip() + "\n"


def _render_markdown_notes(data: ReleaseData) -> str:
    heading = str(data["title"]).strip()
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
            "Convert app/assets/whats_new/releases.json into Google Play and "
            "archive-friendly release notes."
        )
    )
    parser.add_argument(
        "--source",
        type=Path,
        default=Path("app/assets/whats_new/releases.json"),
        help="Baskit versioned What's New release catalog to export.",
    )
    parser.add_argument(
        "--version",
        help="Semantic app version to export. Defaults to the version in --pubspec.",
    )
    parser.add_argument(
        "--pubspec",
        type=Path,
        default=Path("app/pubspec.yaml"),
        help="pubspec.yaml used to infer --version when omitted.",
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

    version = args.version or _read_pubspec_version(args.pubspec)
    data = _select_release(_load_json(args.source), args.source, version)
    play_notes = _render_play_notes(data)
    if len(play_notes) > args.max_play_chars:
        raise SystemExit(
            f"Rendered Play release notes are {len(play_notes)} characters; "
            f"maximum is {args.max_play_chars}. Shorten {args.source} entry for {version}."
        )

    markdown_notes = _render_markdown_notes(data)
    _write(args.play_output, play_notes)
    _write(args.markdown_output, markdown_notes)

    print(f"Exported release notes for Baskit {version}")
    print(f"Wrote Play release notes: {args.play_output} ({len(play_notes)} chars)")
    print(f"Wrote Markdown release notes: {args.markdown_output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
