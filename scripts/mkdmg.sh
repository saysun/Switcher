#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP_NAME="Switcher"
APP_BUNDLE="$PROJECT_DIR/$APP_NAME.app"
DMG="$PROJECT_DIR/$APP_NAME.dmg"

cd "$PROJECT_DIR"

echo "Building $APP_NAME..."
swift build -c release

echo "Bundling $APP_BUNDLE..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"
cp ".build/release/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"
cp "Resources/Info.plist" "$APP_BUNDLE/Contents/"
if [[ -f "Resources/Switcher.icns" ]]; then
    cp "Resources/Switcher.icns" "$APP_BUNDLE/Contents/Resources/"
fi

xattr -cr "$APP_BUNDLE"
codesign --force --sign - "$APP_BUNDLE"

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

cp -R "$APP_BUNDLE" "$STAGE/"
ln -sf /Applications "$STAGE/Applications"

echo "Creating $DMG..."
rm -f "$DMG"
hdiutil create \
    -volname "$APP_NAME" \
    -fs HFS+ \
    -srcfolder "$STAGE" \
    -ov \
    -format UDZO \
    "$DMG"

echo "Done: $DMG"
ls -lh "$DMG"
