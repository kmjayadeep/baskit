#!/usr/bin/env python3
"""Export Baskit curated What's New releases into Google Play notes."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any


ReleaseData = dict[str, Any]
IMPORTANCE_RANK = {"high": 0, "medium": 1, "low": 2}


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


def _parse_version(version: str) -> tuple[int, ...]:
    if not re.fullmatch(r"\d+(?:\.\d+)*", version):
        raise SystemExit(f"Unsupported semantic version '{version}'; expected numeric dot format")
    return tuple(int(part) for part in version.split("."))


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
    importance = item.get("importance", "medium")
    if importance is not None and not isinstance(importance, str):
        raise SystemExit(f"{source} item {index} field 'importance' must be a string")
    group = item.get("group")
    if group is not None and not isinstance(group, str):
        raise SystemExit(f"{source} item {index} field 'group' must be a string")
    return item


def _empty_release(version: str) -> ReleaseData:
    return {"version": version, "title": f"Baskit {version}", "items": []}


def _normalize_release(
    source: Path,
    release: Any,
    version: str | None = None,
    *,
    allow_empty: bool = False,
) -> ReleaseData:
    if not isinstance(release, dict):
        raise SystemExit(f"Expected release entry in {source} to be a JSON object")

    release_version = release.get("version")
    title = release.get("title")
    items = release.get("items")

    if not isinstance(release_version, str) or not release_version.strip():
        raise SystemExit(f"{source} release must contain a non-empty string 'version'")
    _parse_version(release_version)
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
    if not eligible_items and not allow_empty:
        raise SystemExit(
            f"{source} release {release_version} has no userFacing=true items to export"
        )

    return {
        "version": release_version,
        "title": title or f"Baskit {release_version}",
        "items": eligible_items,
    }


def _release_list(data: dict[str, Any], source: Path) -> list[ReleaseData]:
    if isinstance(data.get("releases"), list):
        return [_normalize_release(source, release, allow_empty=True) for release in data["releases"]]

    # Backward-compatible support for the old latest.json shape.
    return [_normalize_release(source, data, allow_empty=True)]


def _select_release(
    data: dict[str, Any],
    source: Path,
    version: str | None,
    *,
    allow_empty: bool = False,
) -> ReleaseData:
    if isinstance(data.get("releases"), list):
        if not version:
            raise SystemExit(
                "A --version value or readable --pubspec is required when exporting releases.json"
            )
        matches = [release for release in data["releases"] if release.get("version") == version]
        if not matches:
            if allow_empty:
                return _empty_release(version)
            raise SystemExit(f"No release entry found for version {version} in {source}")
        return _normalize_release(source, matches[-1], version, allow_empty=allow_empty)

    # Backward-compatible support for the old latest.json shape.
    return _normalize_release(source, data, version, allow_empty=allow_empty)


def _read_promotion_baseline(promotion_state: Path) -> str:
    data = _load_json(promotion_state)
    baseline = data.get("lastUserVisibleVersion")
    if not isinstance(baseline, str) or not baseline.strip():
        raise SystemExit(
            f"{promotion_state} must contain a non-empty string 'lastUserVisibleVersion'"
        )
    _parse_version(baseline)
    return baseline


def _importance_rank(item: ReleaseData) -> int:
    importance = str(item.get("importance") or "medium").lower()
    return IMPORTANCE_RANK.get(importance, IMPORTANCE_RANK["medium"])


def _select_cumulative_release(
    data: dict[str, Any],
    source: Path,
    candidate_version: str,
    since_version: str,
    *,
    max_items: int,
    allow_empty: bool = False,
) -> ReleaseData:
    if max_items < 1:
        raise SystemExit("--max-items must be at least 1")

    since_key = _parse_version(since_version)
    candidate_key = _parse_version(candidate_version)
    if since_key >= candidate_key:
        raise SystemExit(
            f"Cumulative notes range is empty: --since-version {since_version} must be less than {candidate_version}"
        )

    selected_releases = sorted(
        [
            release
            for release in _release_list(data, source)
            if since_key < _parse_version(release["version"]) <= candidate_key
        ],
        key=lambda release: _parse_version(release["version"]),
    )

    if not selected_releases:
        if allow_empty:
            return _empty_release(candidate_version)
        raise SystemExit(
            f"No release entries found in {source} after {since_version} through {candidate_version}"
        )

    deduped: dict[str, tuple[ReleaseData, str, tuple[int, ...]]] = {}
    ungrouped: list[tuple[ReleaseData, str, tuple[int, ...]]] = []
    for release in selected_releases:
        release_version = release["version"]
        version_key = _parse_version(release_version)
        for item in release["items"]:
            record = (item, release_version, version_key)
            group = (item.get("group") or "").strip()
            if not group:
                ungrouped.append(record)
                continue

            current = deduped.get(group)
            if current is None:
                deduped[group] = record
                continue

            current_item, _current_version, current_version_key = current
            if (
                _importance_rank(item), tuple(-part for part in version_key)
            ) < (
                _importance_rank(current_item), tuple(-part for part in current_version_key)
            ):
                deduped[group] = record

    records = list(deduped.values()) + ungrouped
    records.sort(
        key=lambda record: (
            _importance_rank(record[0]),
            tuple(-part for part in record[2]),
            str(record[0]["title"]).lower(),
        )
    )
    items = [record[0] for record in records[:max_items]]

    if not items and not allow_empty:
        raise SystemExit(
            f"No userFacing=true items found in {source} after {since_version} through {candidate_version}"
        )

    return {
        "version": candidate_version,
        "title": f"Baskit {candidate_version}: highlights since {since_version}",
        "items": items,
        "sinceVersion": since_version,
    }


def _render_play_notes(data: ReleaseData) -> str:
    heading = str(data["title"]).strip()
    lines = [heading]

    if not data["items"]:
        lines.append(
            "Bug fixes, performance improvements, and "
            "behind-the-scenes updates to keep Baskit running smoothly."
        )
    else:
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
    lines = [f"# {heading}", "", f"Version: `{data['version']}`"]
    if data.get("sinceVersion"):
        lines.append(f"Since promoted baseline: `{data['sinceVersion']}`")
    lines.append("")

    if not data["items"]:
        lines.append(
            "Bug fixes, performance improvements, and "
            "behind-the-scenes updates to keep Baskit running smoothly."
        )
    else:
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
        "--mode",
        choices=("single", "cumulative"),
        default="single",
        help="Export only --version, or aggregate highlights since a promotion baseline.",
    )
    parser.add_argument(
        "--since-version",
        help="Promotion baseline version for --mode cumulative.",
    )
    parser.add_argument(
        "--promotion-state",
        type=Path,
        default=Path("docs/release-promotion-state.json"),
        help="JSON file containing lastUserVisibleVersion for cumulative exports.",
    )
    parser.add_argument(
        "--max-items",
        type=int,
        default=5,
        help="Maximum number of deduplicated user-facing items in cumulative mode.",
    )
    parser.add_argument(
        "--allow-empty",
        action="store_true",
        help=(
            "Write a title-only note when the selected release/range has no eligible "
            "user-facing highlights."
        ),
    )
    parser.add_argument(
        "--play-output",
        type=Path,
        default=Path("release-artifacts/whatsnew-en-GB"),
        help="Google Play whatsNewDirectory locale file to write (use whatsnew-<locale> naming).",
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
    release_source = _load_json(args.source)
    if args.mode == "single":
        data = _select_release(
            release_source,
            args.source,
            version,
            allow_empty=args.allow_empty,
        )
        summary = f"Baskit {version}"
    else:
        since_version = args.since_version
        if not since_version:
            if not args.promotion_state.exists():
                raise SystemExit(
                    "Cumulative mode requires --since-version or an existing --promotion-state file"
                )
            since_version = _read_promotion_baseline(args.promotion_state)
        data = _select_cumulative_release(
            release_source,
            args.source,
            version,
            since_version,
            max_items=args.max_items,
            allow_empty=args.allow_empty,
        )
        summary = f"Baskit {version} since {since_version}"

    play_notes = _render_play_notes(data)
    if len(play_notes) > args.max_play_chars:
        hint = "Reduce low-importance items, shorten descriptions, or lower --max-items."
        raise SystemExit(
            f"Rendered Play release notes are {len(play_notes)} characters; "
            f"maximum is {args.max_play_chars}. {hint} Source: {args.source}."
        )

    markdown_notes = _render_markdown_notes(data)
    _write(args.play_output, play_notes)
    _write(args.markdown_output, markdown_notes)

    print(f"Exported release notes for {summary}")
    print(f"Wrote Play release notes: {args.play_output} ({len(play_notes)} chars)")
    print(f"Wrote Markdown release notes: {args.markdown_output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
