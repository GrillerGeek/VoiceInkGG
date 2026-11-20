#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIGURATION="${ROBEY_VOICE_CONFIGURATION:-Release}"
DERIVED="${ROBEY_VOICE_DERIVED_DATA:-$ROOT/.review-build/DerivedData}"
DERIVED="$(python3 -c 'from pathlib import Path; import sys; print(Path(sys.argv[1]).expanduser().resolve())' "$DERIVED")"
[[ "$DERIVED" == "$ROOT/.review-build/"* ]] || { echo 'DerivedData must stay beneath ignored .review-build/' >&2; exit 1; }
IDENTITY="${ROBEY_VOICE_SIGNING_IDENTITY:-}"
mkdir -p "$ROOT/.review-build" "$ROOT/.local-dependencies"
if [[ -z "$IDENTITY" ]]; then
    IDENTITIES=()
    while IFS= read -r value; do [[ -n "$value" ]] && IDENTITIES+=("$value"); done < <(security find-identity -v -p codesigning | awk '/"Apple Development: / { print $2 }')
    if [[ "${#IDENTITIES[@]}" == 1 ]]; then IDENTITY="${IDENTITIES[0]}"; else IDENTITY=-; fi
fi
echo "Local signing identity: $IDENTITY"
echo "A development/ad-hoc signature is not notarized distribution."
"$ROOT/scripts/resolve-packages.sh"
python3 "$ROOT/scripts/validate-dependencies.py"
python3 "$ROOT/scripts/build-provenance.py" begin "$DERIVED/robey-build-record.json"
xcodebuild -project "$ROOT/VoiceInk.xcodeproj" -scheme VoiceInk -configuration "$CONFIGURATION" \
    -derivedDataPath "$DERIVED" -clonedSourcePackagesDirPath "$ROOT/.local-dependencies/SourcePackages" \
    -packageCachePath "$ROOT/.local-dependencies/PackageCache" \
    -onlyUsePackageVersionsFromResolvedFile -disableAutomaticPackageResolution -xcconfig "$ROOT/LocalBuild.xcconfig" \
    CODE_SIGN_IDENTITY="$IDENTITY" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=YES \
    ARCHS="${ROBEY_VOICE_ARCH:-arm64}" ONLY_ACTIVE_ARCH=YES \
    -skipPackagePluginValidation -skipMacroValidation build
if [[ "$CONFIGURATION" == Debug ]]; then APP="$DERIVED/Build/Products/Debug/Robey Voice Dev.app"; else APP="$DERIVED/Build/Products/Release/Robey Voice.app"; fi
"$ROOT/scripts/verify-app.sh" "$APP"
python3 "$ROOT/scripts/validate-dependencies.py"
python3 "$ROOT/scripts/build-provenance.py" finish "$DERIVED/robey-build-record.json" "$APP"
