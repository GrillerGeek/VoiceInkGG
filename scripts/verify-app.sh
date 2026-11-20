#!/usr/bin/env bash
set -euo pipefail
APP="${1:?Usage: scripts/verify-app.sh path/to/Robey Voice.app}"
[[ -d "$APP" ]] || { echo "Missing app: $APP" >&2; exit 1; }
codesign --verify --deep --strict --verbose=2 "$APP"
codesign -dv --verbose=4 "$APP" 2>&1
while IFS= read -r -d '' binary; do
    if file -b "$binary" | grep -q 'Mach-O'; then
        printf '\n%s\n' "$binary"
        lipo -archs "$binary"
        codesign --verify --strict --verbose=2 "$binary"
        otool -L "$binary"
    fi
done < <(find "$APP" -type f -print0)
