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
STAGING_DIR="$REPO_ROOT/build/dmg-staging"
FINAL_DMG="$OUTPUT_DIR/${DMG_NAME}.dmg"

rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR" "$OUTPUT_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

rm -f "$FINAL_DMG"

diskutil image create from \
	--format UDZO \
	--volumeName "Drift" \
	"$STAGING_DIR" \
	"$FINAL_DMG" >/dev/null

rm -rf "$STAGING_DIR"

echo "$FINAL_DMG"
