#!/bin/bash
# Regenerate Resources/Switcher.icns from a source PNG (default: new_app_icon.png).
# The app bundle only reads Switcher.icns — editing the PNG alone does nothing until you run this.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SRC="${1:-"$PROJECT_DIR/new_app_icon.png"}"
OUT_ICNS="$PROJECT_DIR/Resources/Switcher.icns"

if [[ ! -f "$SRC" ]]; then
    echo "make-icon.sh: source image not found: $SRC" >&2
    exit 1
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/switcher.icnswork.XXXXXX")"
ICONSET="$TMP/AppIcon.iconset"
mkdir "$ICONSET"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

sips -z 16 16 "$SRC" --out "$ICONSET/icon_16x16.png" >/dev/null
sips -z 32 32 "$SRC" --out "$ICONSET/icon_16x16@2x.png" >/dev/null
sips -z 32 32 "$SRC" --out "$ICONSET/icon_32x32.png" >/dev/null
sips -z 64 64 "$SRC" --out "$ICONSET/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "$SRC" --out "$ICONSET/icon_128x128.png" >/dev/null
sips -z 256 256 "$SRC" --out "$ICONSET/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$SRC" --out "$ICONSET/icon_256x256.png" >/dev/null
sips -z 512 512 "$SRC" --out "$ICONSET/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$SRC" --out "$ICONSET/icon_512x512.png" >/dev/null
sips -z 1024 1024 "$SRC" --out "$ICONSET/icon_512x512@2x.png" >/dev/null

mkdir -p "$(dirname "$OUT_ICNS")"
iconutil -c icns "$ICONSET" -o "$OUT_ICNS"
echo "Wrote $OUT_ICNS"
echo "Next: ./scripts/bundle.sh or ./scripts/mkdmg.sh, then ./scripts/refresh-app-icon.sh"
