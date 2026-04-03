#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP_NAME="Switcher"
APP_BUNDLE="$PROJECT_DIR/$APP_NAME.app"

cd "$PROJECT_DIR"

echo "Building $APP_NAME..."
swift build -c release

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"

cp ".build/release/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"
cp "Resources/Info.plist" "$APP_BUNDLE/Contents/"

xattr -cr "$APP_BUNDLE"
codesign --force --sign - "$APP_BUNDLE"

echo ""
echo "Done — $APP_NAME.app created."
echo ""
echo "  Run:      open $APP_NAME.app"
echo "  Install:  cp -r $APP_NAME.app /Applications/"
