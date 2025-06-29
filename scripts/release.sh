#!/usr/bin/env bash

# Baskit Release Script
# Usage: ./scripts/release.sh [patch|minor|major]
#
# Version format: MAJOR.MINOR.PATCH+BUILD
# - MAJOR.MINOR.PATCH: Semantic version for app releases
# - BUILD: Google Play Store version code (always increments)

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

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

# Confirm with user
read -p "Continue with release $NEW_FULL_VERSION? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Release cancelled."
    exit 1
fi

# Update pubspec.yaml
sed -i "s/^version:.*/version: ${NEW_FULL_VERSION}/" app/pubspec.yaml

echo -e "${YELLOW}Updated app/pubspec.yaml${NC}"

# Stage and commit the version change
git add app/pubspec.yaml
git commit -m "chore: bump version to $NEW_FULL_VERSION"

# Create and push tag
TAG_NAME="v$NEW_VERSION"
git tag -a "$TAG_NAME" -m "Release $NEW_VERSION

- Semantic version: $NEW_VERSION
- Google Play version code: $NEW_BUILD
- Full version: $NEW_FULL_VERSION
- Release type: $BUMP_TYPE"

echo -e "${GREEN}Created tag: $TAG_NAME${NC}"

# Push commit and tag
echo -e "${YELLOW}Pushing to origin...${NC}"
git push origin main
git push origin "$TAG_NAME"

echo -e "${GREEN}✅ Release $NEW_FULL_VERSION created successfully!${NC}"
echo -e "${YELLOW}GitHub Actions will now build and create the release.${NC}"
echo -e "${YELLOW}Check: https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]//' | sed 's/.git$//')/actions${NC}" 