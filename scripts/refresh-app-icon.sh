#!/bin/bash
# Bust macOS icon / LaunchServices caches for an installed Switcher.app.
set -euo pipefail

APP="${1:-/Applications/Switcher.app}"

if [[ ! -d "$APP" ]]; then
    echo "refresh-app-icon.sh: not found: $APP" >&2
    echo "Usage: $0 [/path/to/Switcher.app]" >&2
    exit 1
fi

echo "Clearing xattrs on $APP ..."
xattr -cr "$APP"

echo "Re-registering with Launch Services..."
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP"

echo "Touching bundle..."
touch "$APP"

echo "Restarting Finder and Dock (icons redraw)..."
killall Finder 2>/dev/null || true
killall Dock 2>/dev/null || true

echo "Done. If the icon is still wrong, log out and back in, or reboot once."
