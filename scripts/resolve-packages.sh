#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/.local-dependencies"
xcodebuild -resolvePackageDependencies -project "$ROOT/VoiceInk.xcodeproj" -scheme VoiceInk \
    -clonedSourcePackagesDirPath "$ROOT/.local-dependencies/SourcePackages" \
    -packageCachePath "$ROOT/.local-dependencies/PackageCache" \
    -onlyUsePackageVersionsFromResolvedFile -disableAutomaticPackageResolution
python3 "$ROOT/scripts/validate-dependencies.py"
