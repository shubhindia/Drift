#!/usr/bin/env bash

set -euo pipefail

usage() {
	cat >&2 <<'USAGE'
usage: scripts/build_local_dmg.sh [dmg-name]

Builds Drift locally using the same unsigned Release build path as CI, then
packages the app into a DMG under build/dist.

Environment overrides:
  CONFIGURATION       Build configuration. Defaults to Release.
  DERIVED_DATA_PATH   DerivedData output path. Defaults to build/DerivedData.
  DIST_DIR            DMG output directory. Defaults to build/dist.
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
	usage
	exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PROJECT_PATH="$REPO_ROOT/Drift.xcodeproj"
SCHEME="Drift"
CONFIGURATION="${CONFIGURATION:-Release}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$REPO_ROOT/build/DerivedData}"
DIST_DIR="${DIST_DIR:-$REPO_ROOT/build/dist}"
DMG_NAME="${1:-Drift-local}"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/Drift.app"

if ! command -v xcodebuild >/dev/null 2>&1; then
	echo "xcodebuild not found. Install Xcode and select it with xcode-select." >&2
	exit 1
fi

if ! command -v diskutil >/dev/null 2>&1; then
	echo "diskutil not found. This script must be run on macOS." >&2
	exit 1
fi

if [[ ! -x "$SCRIPT_DIR/create_dmg.sh" ]]; then
	chmod +x "$SCRIPT_DIR/create_dmg.sh"
fi

echo "Building $SCHEME ($CONFIGURATION)..."
xcodebuild \
	-project "$PROJECT_PATH" \
	-scheme "$SCHEME" \
	-configuration "$CONFIGURATION" \
	-destination 'platform=macOS' \
	-derivedDataPath "$DERIVED_DATA_PATH" \
	CODE_SIGNING_ALLOWED=NO \
	build

if [[ ! -d "$APP_PATH" ]]; then
	echo "expected app bundle not found after build: $APP_PATH" >&2
	exit 1
fi

echo "Creating DMG..."
DMG_PATH="$("$SCRIPT_DIR/create_dmg.sh" "$APP_PATH" "$DIST_DIR" "$DMG_NAME")"

echo "Created $DMG_PATH"
