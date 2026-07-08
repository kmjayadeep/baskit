#!/usr/bin/env bash

# Record the latest Baskit version promoted to a user-visible Google Play track.
# Usage: ./scripts/mark_promoted.sh VERSION --track closed|open|production

set -euo pipefail

print_usage() {
    cat <<'EOF'
Usage: ./scripts/mark_promoted.sh VERSION --track closed|open|production

Updates docs/release-promotion-state.json after manually promoting a Play release
from internal testing to a user-visible track.
EOF
}

if [[ ${1:-} == "--help" || ${1:-} == "-h" || $# -lt 3 ]]; then
    print_usage
    exit $([[ ${1:-} == "--help" || ${1:-} == "-h" ]] && echo 0 || echo 1)
fi

VERSION=$1
shift
TRACK=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --track)
            TRACK=${2:-}
            shift 2
            ;;
        *)
            echo "Unexpected argument: $1" >&2
            print_usage
            exit 1
            ;;
    esac
done

if [[ ! $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Version must use MAJOR.MINOR.PATCH format: $VERSION" >&2
    exit 1
fi

if [[ ! $TRACK =~ ^(closed|open|production)$ ]]; then
    echo "--track must be one of: closed, open, production" >&2
    exit 1
fi

RELEASES_FILE="app/assets/whats_new/releases.json"
STATE_FILE="docs/release-promotion-state.json"

python3 - "$RELEASES_FILE" "$STATE_FILE" "$VERSION" "$TRACK" <<'PY'
import datetime as dt
import json
import sys
from pathlib import Path

releases_path = Path(sys.argv[1])
state_path = Path(sys.argv[2])
version = sys.argv[3]
track = sys.argv[4]

try:
    data = json.loads(releases_path.read_text(encoding="utf-8"))
except FileNotFoundError:
    raise SystemExit(f"Release catalog not found: {releases_path}")
except json.JSONDecodeError as exc:
    raise SystemExit(f"Invalid JSON in {releases_path}: {exc}")

releases = data.get("releases")
if not isinstance(releases, list):
    raise SystemExit(f'{releases_path} must contain a top-level "releases" array')
if not any(isinstance(release, dict) and release.get("version") == version for release in releases):
    raise SystemExit(f"Version {version} does not exist in {releases_path}; add curated notes before marking it promoted")


def parse_version(value: str) -> tuple[int, int, int]:
    try:
        parts = tuple(int(part) for part in value.split("."))
    except ValueError as exc:
        raise SystemExit(f"Invalid version in promotion state: {value}") from exc
    if len(parts) != 3:
        raise SystemExit(f"Invalid version in promotion state: {value}")
    return parts


if state_path.exists():
    try:
        current_state = json.loads(state_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise SystemExit(f"Invalid JSON in {state_path}: {exc}") from exc
    current_version = current_state.get("lastUserVisibleVersion")
    if isinstance(current_version, str) and current_version.strip():
        if parse_version(version) <= parse_version(current_version):
            raise SystemExit(
                f"Refusing to move promotion baseline from {current_version} to {version}; "
                "mark only a newer user-visible promotion"
            )

state = {
    "lastUserVisibleVersion": version,
    "track": track,
    "updatedAt": dt.date.today().isoformat(),
}
state_path.parent.mkdir(parents=True, exist_ok=True)
state_path.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
print(f"Updated {state_path} to {version} ({track})")
PY

cat <<EOF

Promotion baseline updated.

Checklist:
- Confirm Play Console shows version $VERSION promoted to the $TRACK track.
- Open a small PR containing $STATE_FILE.
- Merge only after the Play promotion is live for testers/users.
EOF
