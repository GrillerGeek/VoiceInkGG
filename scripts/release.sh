#!/usr/bin/env bash
# Local manual-update packaging. No feed, publication, paid service or account creation.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/.review-build/DerivedData/Build/Products/Release/Robey Voice.app"
OUTPUT="$ROOT/.review-build/package-$(date -u +%Y%m%dT%H%M%SZ)"
NOTARY_PROFILE=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --app) APP="${2:?--app requires a path}"; shift 2 ;;
        --output-dir) OUTPUT="${2:?--output-dir requires a path}"; shift 2 ;;
        --notary-profile) NOTARY_PROFILE="${2:?--notary-profile requires an existing Keychain profile}"; shift 2 ;;
        --skip-notarization|--skip-appcast|--allow-dirty) shift ;;
        -h|--help) echo 'scripts/release.sh [--app path] [--output-dir ignored-path] [--notary-profile existing-profile]'; exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done
OUTPUT="$(python3 -c 'from pathlib import Path; import sys; print(Path(sys.argv[1]).expanduser().resolve())' "$OUTPUT")"
[[ "$OUTPUT" == "$ROOT/.review-build/"* ]] || { echo "Package output must stay beneath ignored .review-build/" >&2; exit 1; }
[[ ! -e "$OUTPUT" ]] || { echo "Refusing to overwrite existing package output" >&2; exit 1; }
APP="$(python3 -c 'from pathlib import Path; import sys; print(Path(sys.argv[1]).resolve())' "$APP")"
RECORD="${ROBEY_VOICE_BUILD_RECORD:-$ROOT/.review-build/DerivedData/robey-build-record.json}"
python3 "$ROOT/scripts/build-provenance.py" verify "$RECORD" "$APP"
"$ROOT/scripts/verify-app.sh" "$APP"
[[ "$(plutil -extract CFBundleIdentifier raw "$APP/Contents/Info.plist")" == com.jasonrobey.RobeyVoice ]] || { echo 'A Release Robey Voice application is required' >&2; exit 1; }
mkdir -p "$OUTPUT/staging"
ditto "$APP" "$OUTPUT/staging/Robey Voice.app"
ln -s /Applications "$OUTPUT/staging/Applications"
SIGNATURE="$(codesign -dv --verbose=4 "$APP" 2>&1)"
STATUS='Local review build: ad-hoc signed; not notarized.'
if [[ "$SIGNATURE" == *'Authority=Developer ID Application:'* ]]; then
    STATUS='Developer ID signed; not notarized.'
elif [[ "$SIGNATURE" == *'Authority=Apple Development:'* ]]; then
    STATUS='Local review build: Apple Development signed; not notarized.'
fi
if [[ -n "$NOTARY_PROFILE" ]]; then
    [[ "$SIGNATURE" == *'Authority=Developer ID Application:'* ]] || { echo 'Notarization requires rebuilding with an available Developer ID Application identity' >&2; exit 1; }
    STATUS='Developer ID signed. Check adjacent DISTRIBUTION-STATUS.txt and notarization evidence for this package.'
fi
printf '%s\n\n%s\n' 'Robey Voice — manual installation' "$STATUS" > "$OUTPUT/staging/INSTALL.txt"
cat >> "$OUTPUT/staging/INSTALL.txt" <<'EOF'
Requires Apple silicon and macOS 15 or later. Intel is not verified.
Quit the previous Robey Voice before dragging the app into Applications.
Replacing a Robey Voice build preserves its separate Application Support data.
Keep a backup of your previous app to roll back. VoiceInk data is not imported
automatically. Permissions use normal macOS approval and may need reapproval.
This local artifact is for review on the build owner's Macs; another Mac may
reject a development or ad-hoc signature. A notarized Developer ID build is
required for normal independent distribution. No automatic update feed exists.
EOF
DMG="$OUTPUT/Robey-Voice-0.1.0-arm64.dmg"
hdiutil create -volname 'Robey Voice' -srcfolder "$OUTPUT/staging" -format UDZO -ov "$DMG"
if [[ -n "$NOTARY_PROFILE" ]]; then
    xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait --output-format json > "$OUTPUT/notarization.json"
    python3 -c 'import json,sys; assert json.load(open(sys.argv[1]))["status"] == "Accepted"' "$OUTPUT/notarization.json"
    xcrun stapler staple "$DMG"
    xcrun stapler validate "$DMG"
    STATUS='Developer ID signed and notarized; ticket stapled to DMG.'
fi
hdiutil verify "$DMG"
python3 "$ROOT/scripts/build-provenance.py" verify "$RECORD" "$APP"
python3 "$ROOT/scripts/package-source.py" "$OUTPUT" "$RECORD"
cp "$RECORD" "$OUTPUT/build-record.json"
printf '%s\n' "$STATUS" > "$OUTPUT/DISTRIBUTION-STATUS.txt"
(cd "$OUTPUT" && shasum -a 256 ./*.dmg ./*.tar.gz source-provenance.json build-record.json DISTRIBUTION-STATUS.txt > SHA256SUMS.txt)
echo "Review package: $OUTPUT"
