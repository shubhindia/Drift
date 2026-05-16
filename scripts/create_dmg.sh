#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 2 ]]; then
	echo "usage: $0 /path/to/Drift.app /path/to/output-dir [dmg-name]" >&2
	exit 1
fi

APP_PATH="$1"
OUTPUT_DIR="$2"
DMG_NAME="${3:-Drift}"

if [[ ! -d "$APP_PATH" ]]; then
	echo "app bundle not found: $APP_PATH" >&2
	exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
STAGING_DIR="$REPO_ROOT/.build/dmg-staging"
TEMP_DMG="$REPO_ROOT/.build/${DMG_NAME}-temp.dmg"
FINAL_DMG="$OUTPUT_DIR/${DMG_NAME}.dmg"

rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR" "$OUTPUT_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

rm -f "$TEMP_DMG" "$FINAL_DMG"

hdiutil create \
	-volname "Drift" \
	-srcfolder "$STAGING_DIR" \
	-ov \
	-format UDRW \
	"$TEMP_DMG" >/dev/null

hdiutil convert "$TEMP_DMG" \
	-ov \
	-format UDZO \
	-imagekey zlib-level=9 \
	-o "$FINAL_DMG" >/dev/null

rm -f "$TEMP_DMG"
rm -rf "$STAGING_DIR"

echo "$FINAL_DMG"
