#!/usr/bin/env bash

# Baskit Release Archiver
# Archives AAB, APK, debug symbols, release notes, and validation logs for a given version tag.
#
# Usage: ./scripts/archive-release.sh <version-tag>
# Example: ./scripts/archive-release.sh v1.2.0
#
# The script expects the release artifacts to have been built (via CI or locally).
# It creates a timestamped archive directory with all artifacts.

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

VERSION_TAG="${1:-}"

if [[ -z "$VERSION_TAG" ]]; then
    echo -e "${RED}Error: Version tag is required.${NC}"
    echo "Usage: $0 <version-tag>"
    echo "Example: $0 v1.2.0"
    exit 1
fi

# Determine archive directory
ARCHIVE_ROOT="releases"
ARCHIVE_DIR="${ARCHIVE_ROOT}/${VERSION_TAG}"
TIMESTAMP=$(date -u +'%Y-%m-%d_%H%M%S')

echo -e "${YELLOW}Archiving release artifacts for ${VERSION_TAG}...${NC}"

# Check if we're in the project root
if [[ ! -f "app/pubspec.yaml" ]]; then
    echo -e "${RED}Error: app/pubspec.yaml not found. Run from project root.${NC}"
    exit 1
fi

# Check if this version has already been archived
if [[ -d "$ARCHIVE_DIR" ]]; then
    echo -e "${YELLOW}⚠️  Archive directory already exists: ${ARCHIVE_DIR}${NC}"
    read -p "Overwrite existing archive? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Archive cancelled."
        exit 0
    fi
    rm -rf "$ARCHIVE_DIR"
fi

mkdir -p "$ARCHIVE_DIR"

# Define artifact paths
AAB_PATH="app/build/app/outputs/bundle/release/app-release.aab"
APK_PATH="app/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
SYMBOLS_DIR="app/build/app/outputs/symbols"
BUILD_REPORTS_DIR="app/build/reports"

# Track what we find
MISSING=()

# ---- Copy AAB ----
if [[ -f "$AAB_PATH" ]]; then
    cp "$AAB_PATH" "$ARCHIVE_DIR/"
    echo -e "${GREEN}✅ AAB archived${NC}"
else
    MISSING+=("AAB ($AAB_PATH)")
    echo -e "${YELLOW}⚠️  AAB not found${NC}"
fi

# ---- Copy APK ----
if [[ -f "$APK_PATH" ]]; then
    cp "$APK_PATH" "$ARCHIVE_DIR/"
    echo -e "${GREEN}✅ APK archived${NC}"
else
    MISSING+=("APK ($APK_PATH)")
    echo -e "${YELLOW}⚠️  APK not found${NC}"
fi

# ---- Package and copy debug symbols ----
if [[ -d "$SYMBOLS_DIR" ]] && [[ -n "$(ls -A "$SYMBOLS_DIR" 2>/dev/null)" ]]; then
    SYMBOLS_ZIP="${ARCHIVE_DIR}/debug-symbols.zip"
    (cd "$SYMBOLS_DIR" && zip -qr "${PWD}/../../../${SYMBOLS_ZIP}" .)
    echo -e "${GREEN}✅ Debug symbols archived${NC}"
else
    MISSING+=("Debug symbols ($SYMBOLS_DIR)")
    echo -e "${YELLOW}⚠️  Debug symbols not found${NC}"
fi

# ---- Copy build reports (validation logs) ----
if [[ -d "$BUILD_REPORTS_DIR" ]]; then
    cp -r "$BUILD_REPORTS_DIR" "$ARCHIVE_DIR/build-reports"
    echo -e "${GREEN}✅ Build reports archived${NC}"
else
    echo -e "${YELLOW}⚠️  Build reports not found (skipping)${NC}"
fi

# ---- Copy APK output directory listing for logs ----
APK_OUTPUT_DIR="app/build/app/outputs/flutter-apk"
if [[ -d "$APK_OUTPUT_DIR" ]]; then
    ls -la "$APK_OUTPUT_DIR" > "$ARCHIVE_DIR/apk-output-listing.txt"
    echo -e "${GREEN}✅ APK output listing saved${NC}"
fi

# ---- Generate release manifest ----
MANIFEST="${ARCHIVE_DIR}/release-manifest.txt"
{
    echo "================================================"
    echo "Baskit Release Archive: ${VERSION_TAG}"
    echo "================================================"
    echo "Archived at: ${TIMESTAMP} UTC"
    echo "Git commit:  $(git rev-parse HEAD)"
    echo "Git tag:     ${VERSION_TAG}"
    echo ""
    echo "Contents:"
    echo "---------"
    ls -la "$ARCHIVE_DIR/"
    echo ""
    echo "Version info from pubspec.yaml:"
    echo "------------------------------"
    grep "^version:" app/pubspec.yaml || echo "  (not found)"
    echo ""
    if [[ ${#MISSING[@]} -gt 0 ]]; then
        echo "⚠️  Missing artifacts:"
        for item in "${MISSING[@]}"; do
            echo "  - $item"
        done
    else
        echo "✅ All artifacts present."
    fi
    echo "================================================"
} > "$MANIFEST"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Archive complete: ${ARCHIVE_DIR}${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

if [[ ${#MISSING[@]} -gt 0 ]]; then
    echo -e "${YELLOW}⚠️  Some artifacts were not found:${NC}"
    for item in "${MISSING[@]}"; do
        echo -e "${YELLOW}  - $item${NC}"
    done
    echo ""
    echo -e "${YELLOW}Build the release first:${NC}"
    echo "  cd app && flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols"
    echo "  cd app && flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/app/outputs/symbols"
fi

echo -e "${GREEN}Release manifest: ${MANIFEST}${NC}"
