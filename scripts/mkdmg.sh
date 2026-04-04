#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP_NAME="Switcher"
APP_BUNDLE="$PROJECT_DIR/$APP_NAME.app"
DMG="$PROJECT_DIR/$APP_NAME.dmg"
CREATE_DMG="$SCRIPT_DIR/vendor/create-dmg/create-dmg"

cd "$PROJECT_DIR"

echo "Bumping version (patch +1)..."
"$SCRIPT_DIR/bump-version.sh" "$PROJECT_DIR/Resources/Info.plist"

if [[ ! -x "$CREATE_DMG" ]]; then
    echo "Missing vendored create-dmg at: $CREATE_DMG"
    exit 1
fi

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

echo "Generating DMG window background..."
swift "$SCRIPT_DIR/generate_dmg_background.swift" "$PROJECT_DIR/Resources/dmg-background.png"

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
cp -R "$APP_BUNDLE" "$STAGE/"

echo "Creating styled DMG (Finder layout + drag-to-Applications)..."
rm -f "$DMG"

DMG_ARGS=(
    --volname "$APP_NAME"
    --background "$PROJECT_DIR/Resources/dmg-background.png"
    --window-pos 200 120
    --window-size 660 440
    --icon-size 112
    --text-size 13
    --icon "$APP_NAME.app" 175 188
    --hide-extension "$APP_NAME.app"
    --app-drop-link 430 188
    --no-internet-enable
    --filesystem HFS+
)
if [[ -f "Resources/Switcher.icns" ]]; then
    DMG_ARGS+=(--volicon "$PROJECT_DIR/Resources/Switcher.icns")
fi

"$CREATE_DMG" "${DMG_ARGS[@]}" "$DMG" "$STAGE"

echo "Done: $DMG"
ls -lh "$DMG"
