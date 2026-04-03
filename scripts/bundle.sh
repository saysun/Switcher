#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP_NAME="Switcher"
APP_BUNDLE="$PROJECT_DIR/$APP_NAME.app"
BUNDLE_ID="com.switcher.app"

cd "$PROJECT_DIR"

# 1. Kill any running Switcher
echo "Stopping $APP_NAME..."
pkill -f "$APP_NAME.app/Contents/MacOS/$APP_NAME" 2>/dev/null && sleep 1 || true

# 2. Build
echo "Building $APP_NAME..."
swift build -c release

# 3. Bundle
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
cp ".build/release/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"
cp "Resources/Info.plist" "$APP_BUNDLE/Contents/"

# 4. Sign
xattr -cr "$APP_BUNDLE"
codesign --force --sign - "$APP_BUNDLE"

# 5. Reset accessibility for this app so macOS re-prompts
tccutil reset Accessibility "$BUNDLE_ID" 2>/dev/null || true

# 6. Launch
echo ""
echo "Launching $APP_NAME..."
echo "(Grant Accessibility when prompted)"
echo ""
"$APP_BUNDLE/Contents/MacOS/$APP_NAME" &
disown

echo "Done — $APP_NAME is running."
echo "Install to /Applications:  cp -rf $APP_BUNDLE /Applications/"
