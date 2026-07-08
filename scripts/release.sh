#!/usr/bin/env bash

# Baskit Release Candidate Script
# Usage: ./scripts/release.sh [patch|minor|major]
#
# Creates an internal release candidate tag for builds that may be promoted
# beyond Play internal testing. Use GitHub Actions snapshot artifacts for
# disposable maintainer smoke testing.
#
# Version format: MAJOR.MINOR.PATCH+BUILD
# - MAJOR.MINOR.PATCH: Semantic version for app releases
# - BUILD: Google Play Store version code (always increments)

set -euo pipefail

print_usage() {
    cat <<'EOF'
Usage: ./scripts/release.sh [patch|minor|major]

Creates an internal release candidate. For disposable smoke-testing builds,
use the GitHub Actions snapshot artifact instead of this script.

Arguments:
  patch  Increment the patch version (default)
  minor  Increment the minor version and reset patch to 0
  major  Increment the major version and reset minor and patch to 0

Version format: MAJOR.MINOR.PATCH+BUILD
- MAJOR.MINOR.PATCH: Semantic version for app releases
- BUILD: Google Play Store version code (always increments)
EOF
}

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

if [[ ${1:-} == "--help" || ${1:-} == "-h" ]]; then
    print_usage
    exit 0
fi

# Default to patch if no argument provided
BUMP_TYPE=${1:-patch}

# Validate bump type
if [[ ! "$BUMP_TYPE" =~ ^(patch|minor|major)$ ]]; then
    echo -e "${RED}Error: Invalid bump type. Use 'patch', 'minor', or 'major'${NC}"
    exit 1
fi

# Check if we're in the right directory
if [[ ! -f "app/pubspec.yaml" ]]; then
    echo -e "${RED}Error: app/pubspec.yaml not found. Run this script from project root.${NC}"
    exit 1
fi

# Check if working directory is clean
if [[ -n $(git status --porcelain) ]]; then
    echo -e "${RED}Error: Working directory is not clean. Commit or stash changes first.${NC}"
    exit 1
fi

# Extract current version from pubspec.yaml
CURRENT_VERSION=$(grep "^version:" app/pubspec.yaml | sed 's/version: //' | sed 's/+.*//')
CURRENT_BUILD=$(grep "^version:" app/pubspec.yaml | sed 's/.*+//')

echo -e "${YELLOW}Current version: ${CURRENT_VERSION}+${CURRENT_BUILD}${NC}"
echo -e "${YELLOW}- Current semantic version: ${CURRENT_VERSION}${NC}"
echo -e "${YELLOW}- Current Google Play version code: ${CURRENT_BUILD}${NC}"

# Parse version numbers
IFS='.' read -r -a VERSION_PARTS <<< "$CURRENT_VERSION"
MAJOR=${VERSION_PARTS[0]}
MINOR=${VERSION_PARTS[1]}
PATCH=${VERSION_PARTS[2]}

# Bump version based on type
case $BUMP_TYPE in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        ;;
    patch)
        PATCH=$((PATCH + 1))
        ;;
esac

# Always increment build number (Google Play Store version code)
# This MUST increment for every release regardless of semantic version changes
NEW_BUILD=$((CURRENT_BUILD + 1))
NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
NEW_FULL_VERSION="${NEW_VERSION}+${NEW_BUILD}"

echo -e "${GREEN}New version: ${NEW_FULL_VERSION}${NC}"
echo -e "${YELLOW}- Semantic version: ${NEW_VERSION}${NC}"
echo -e "${YELLOW}- Google Play version code: ${NEW_BUILD}${NC}"

# Check for versioned What's New release content BEFORE making any changes.
RELEASES_FILE="app/assets/whats_new/releases.json"
if [[ ! -f "$RELEASES_FILE" ]]; then
    echo -e "${RED}Error: releases.json file not found: $RELEASES_FILE${NC}"
    echo -e "${YELLOW}Release candidates require curated user-facing What's New content.${NC}"
    echo -e "${YELLOW}Use snapshot workflow artifacts for disposable smoke testing.${NC}"
    exit 1
fi

    echo -e "${GREEN}✅ releases.json file found: $RELEASES_FILE${NC}"

    RELEASES_CHECK=$(python3 - "$RELEASES_FILE" "$NEW_VERSION" <<'PY'
import json
import sys

path, version = sys.argv[1], sys.argv[2]
try:
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
except Exception as exc:
    print(f"ERROR|Invalid JSON in {path}: {exc}")
    sys.exit(0)

releases = data.get("releases")
if not isinstance(releases, list):
    print('ERROR|Missing top-level "releases" array')
    sys.exit(0)

matches = [release for release in releases if str(release.get("version", "")) == version]
if not matches:
    print(f"MISSING|No release entry found for {version}")
    sys.exit(0)

release = matches[-1]
items = release.get("items", [])
eligible_items = [
    item for item in items
    if isinstance(item, dict) and item.get("userFacing") is True
]
if not eligible_items:
    print(f"NO_ELIGIBLE|Release entry for {version} has no userFacing=true items")
    sys.exit(0)

print(f"OK|Versioned release catalog includes {version} with {len(eligible_items)} user-facing item(s)")
PY
)
    RELEASES_STATUS=${RELEASES_CHECK%%|*}
    RELEASES_MESSAGE=${RELEASES_CHECK#*|}

    case "$RELEASES_STATUS" in
        OK)
            echo -e "${GREEN}✅ $RELEASES_MESSAGE${NC}"
            ;;
        ERROR)
            echo -e "${RED}⚠️  ERROR: $RELEASES_MESSAGE${NC}"
            echo "Release cancelled. Fix $RELEASES_FILE and try again."
            exit 1
            ;;
        MISSING|NO_ELIGIBLE)
            echo -e "${RED}⚠️  ERROR: $RELEASES_MESSAGE${NC}"
            echo -e "${YELLOW}Release candidates require curated user-facing highlights in $RELEASES_FILE.${NC}"
            echo -e "${YELLOW}Use snapshot workflow artifacts instead when there are no user-facing release notes.${NC}"
            exit 1
            ;;
        *)
            echo -e "${RED}⚠️  ERROR: Unexpected releases.json validation result: $RELEASES_CHECK${NC}"
            exit 1
            ;;
    esac

# Confirm with user
read -p "Continue with internal release candidate $NEW_FULL_VERSION? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Release candidate cancelled."
    exit 1
fi

# Update pubspec.yaml
sed -i "s/^version:.*/version: ${NEW_FULL_VERSION}/" app/pubspec.yaml

# Update hardcoded version constant
sed -i "s/static const String version = '.*';/static const String version = '${NEW_VERSION}';/" app/lib/constants/app_version.dart

echo -e "${YELLOW}Updated app/pubspec.yaml and app/lib/constants/app_version.dart${NC}"

# Stage and commit the version change
git add app/pubspec.yaml app/lib/constants/app_version.dart
git commit -m "chore: bump version to $NEW_FULL_VERSION"

# Create and push tag
TAG_NAME="v$NEW_VERSION"
git tag -a "$TAG_NAME" -m "Release $NEW_VERSION

- Semantic version: $NEW_VERSION
- Google Play version code: $NEW_BUILD
- Full version: $NEW_FULL_VERSION
- Release type: $BUMP_TYPE
- Candidate status: internal release candidate"

echo -e "${GREEN}Created tag: $TAG_NAME${NC}"

# Push commit and tag
echo -e "${YELLOW}Pushing to origin...${NC}"
git push origin main
git push origin "$TAG_NAME"

echo -e "${GREEN}✅ Internal release candidate $NEW_FULL_VERSION created successfully!${NC}"
echo -e "${YELLOW}GitHub Actions will now build signed artifacts, create a prerelease, and upload to Play internal when configured.${NC}"
echo -e "${YELLOW}Check: https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]//' | sed 's/.git$//')/actions${NC}" 