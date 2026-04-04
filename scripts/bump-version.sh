#!/bin/bash
# Bump CFBundleShortVersionString and CFBundleVersion patch (x.y.Z → x.y.Z+1).
set -euo pipefail

PLIST="${1:-Resources/Info.plist}"
if [[ ! -f "$PLIST" ]]; then
    echo "bump-version.sh: plist not found: $PLIST" >&2
    exit 1
fi

VER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$PLIST" 2>/dev/null || echo "0.0.0")
IFS='.' read -ra PARTS <<< "$VER"
major="${PARTS[0]:-0}"
minor="${PARTS[1]:-0}"
patch="${PARTS[2]:-0}"

if ! [[ "$major" =~ ^[0-9]+$ && "$minor" =~ ^[0-9]+$ && "$patch" =~ ^[0-9]+$ ]]; then
    echo "bump-version.sh: cannot parse version '$VER' (expected major.minor.patch)" >&2
    exit 1
fi

patch=$((patch + 1))
NEW="${major}.${minor}.${patch}"

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $NEW" "$PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $NEW" "$PLIST"
echo "Version → $NEW ($PLIST)"
