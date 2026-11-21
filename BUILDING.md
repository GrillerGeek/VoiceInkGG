# Building Robey Voice

## Requirements

- An Apple silicon Mac; macOS 15.0 is the deployment target. Intel builds are not verified.
- Full Xcode with Swift 6.2 or later, Command Line Tools, and completed first-launch setup. The implementation environment reported Xcode 27.1 and Swift 6.4.
- Git, Python 3.9 or later, and CMake 3.28 or later.
- Network access for initial dependency acquisition and separate speech-model downloads.

Use the Robey Voice checkout or matching source archive, not an upstream VoiceInk clone. The project, scheme, and internal Swift module remain named `VoiceInk`; the Release product is `Robey Voice.app`, version 0.1.0.

The existing Git checkout is the tested build route. Build provenance and source packaging require a Git working tree. If starting from a matching source archive, first verify its package checksums and file manifest, extract it into a new directory, and deliberately import that reviewed snapshot into a local repository:

```bash
cd RobeyVoice-Source
git init
git add -- .
git -c user.name="Local Source Import" -c user.email="source-import@localhost" commit -m "Import verified Robey Voice source snapshot"
```

Run this only in the freshly extracted, reviewed source directory; do not add runtime files or credentials. The commit-local identity options do not alter global Git configuration. No remote or push is needed. Retain the original `source-provenance.json` alongside the imported snapshot. Building this archive import has not been independently repeated; it is distinct from the verified existing-checkout build.

## Prepare Dependencies

Run from the repository root. If CMake is not installed, the workspace-local setup used for this build is:

```bash
python3 -m venv .local-dependencies/tools
.local-dependencies/tools/bin/pip install cmake==4.1.2
make check
make whisper
```

`make check` checks only Git, xcodebuild, and Swift availability. It does not validate CMake, signing, package resolution, or a working app. `scripts/build-whisper.sh` uses `.local-dependencies/tools/bin/cmake`, then CMake on PATH; `ROBEY_VOICE_CMAKE` can select another executable.

The script clones whisper.cpp into `.local-dependencies/whisper.cpp` and checks out v1.8.3 at `2eeeba56e9edd762b4b38467bab96c2517163158`. It builds an arm64 macOS 15 framework with Metal and CoreML by default. The output is `.local-dependencies/whisper.cpp/build-apple/whisper.xcframework`. An existing checkout must match the pin and have no tracked modifications. An existing framework's `robey-build.txt` must match the revision, architecture, and Metal setting; the script refuses to silently update or reuse an incompatible build.

The app build uses the checked-in `VoiceInk.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`, `-onlyUsePackageVersionsFromResolvedFile`, and `-disableAutomaticPackageResolution`. `scripts/resolve-packages.sh` resolves that lock before building, and `scripts/validate-dependencies.py` requires the exact revisions with no tracked modifications. Swift package checkouts and caches stay under `.local-dependencies/SourcePackages` and `.local-dependencies/PackageCache`. A lockfile/graph mismatch is a build failure to investigate, not a reason to discard the lockfile. See the [validation record](docs/robey-voice-validation.md) for current dependency and build status.

## Local Release Build

```bash
make local
```

`make local` and `make build` both prepare the native dependency, build Release under `.review-build/DerivedData`, and run `scripts/verify-app.sh`. The resulting path is:

```text
.review-build/DerivedData/Build/Products/Release/Robey Voice.app
```

The signing script selects the sole available Apple Development identity. If none or several exist, it uses ad-hoc signing. Choose an identity explicitly, or force ad-hoc signing:

```bash
make local LOCAL_CODESIGN_IDENTITY="<identity SHA or name>"
make local LOCAL_CODESIGN_IDENTITY=-
```

`LocalBuild.xcconfig` controls signing only. Unlimited use does not depend on `LOCAL_BUILD`. Both local signature types differ from Developer ID notarized distribution; see the [installation runbook](docs/robey-voice-installation.md).

To use another workspace-owned DerivedData path:

```bash
make local LOCAL_DERIVED_DATA="$PWD/.review-build/DerivedData-review"
```

The canonical DerivedData path must stay beneath ignored `.review-build/`. The build records source/resource input hashes before compilation, verifies signatures and clean dependency revisions, and binds the completed app tree to those inputs in `robey-build-record.json` beside Build products. Packaging rejects an app or build inputs that differ from this record.

The build does not copy an app into Downloads or Applications. `make run` opens the Release app at the selected DerivedData path. `make dev` builds `Robey Voice Dev.app` in Debug with separate data and credentials; it does not launch it. Open that app manually when ready. Direct Xcode work continues to use `VoiceInk.xcodeproj` and the `VoiceInk` scheme after `make whisper`; use the documented script path for the provenance-bound package workflow.

## Checks

```bash
make test
ROBEY_VOICE_APP="$PWD/.review-build/DerivedData/Build/Products/Release/Robey Voice.app" make test
./scripts/verify-app.sh ".review-build/DerivedData/Build/Products/Release/Robey Voice.app"
```

Without `ROBEY_VOICE_APP`, the two real Release artifact checks are explicitly skipped. The script verifies bundle and nested Mach-O signatures, prints architectures and linked libraries, and displays signature details. Neither command establishes notarization, permission recovery, successful transcription, or second-Mac compatibility.

## Package a Local Review Build

```bash
make release
```

`make release` first builds Release, then packages a DMG, matching current-worktree source archive, per-file source provenance, distribution status, and SHA-256 checksums in a new `.review-build/package-<UTC timestamp>` directory. It does not publish anything or generate an update feed. To package an already built app without rebuilding:

```bash
./scripts/release.sh --app ".review-build/DerivedData/Build/Products/Release/Robey Voice.app" --output-dir ".review-build/package-review"
```

The output directory must be new and beneath `.review-build/`. Review the generated `DISTRIBUTION-STATUS.txt`, `source-provenance.json`, `build-record.json`, and `SHA256SUMS.txt`. The source snapshot includes listed uncommitted and reviewed untracked source, not merely HEAD. Packaging rejects unreviewed new files and excludes runtime fixtures, downloaded transcription models, logs, credentials, and dependency caches. It preserves known upstream sound cues and the original tracked MIT-licensed Silero VAD detector (`VoiceInk/Resources/models/ggml-silero-v5.1.2.bin`); these bundled assets are intentional exceptions to generated-media exclusion.

`make release` passes the matching build record automatically, including when `LOCAL_DERIVED_DATA` is customized. When invoking `scripts/release.sh` directly for custom DerivedData, select its matching record explicitly:

```bash
ROBEY_VOICE_BUILD_RECORD="$PWD/.review-build/DerivedData-review/robey-build-record.json" ./scripts/release.sh --app ".review-build/DerivedData-review/Build/Products/Release/Robey Voice.app" --output-dir ".review-build/package-custom"
```

## Developer ID Distribution and Notarization

A normal `make local` build is for local review. Selecting a Developer ID identity alone does not make that build notarization-ready: the verified initial build omitted secure timestamps and injected `com.apple.security.get-task-allow`. The notarized candidate was produced by rerunning Xcode with **both** `OTHER_CODE_SIGN_FLAGS=--timestamp` and `CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO`. Its four binaries/five architecture slices then had Developer ID signatures, secure timestamps and hardened runtime, with no debugging entitlement. The seven declared app entitlements were preserved. All 22 acceptance checks passed.

Use your own installed Developer ID Application identity and an authenticated Keychain profile. The published release includes `SIGNING-RECIPE.txt` with the exact candidate invocation; replace its identity with yours. The following reproduces that distribution-signing route from the repository root, using separate outputs:

```bash
ROBEY_SIGNING_IDENTITY="<Developer ID Application identity SHA or name>"
ROBEY_DERIVED="$PWD/.review-build/DeveloperIDDerivedData"
ROBEY_APP="$ROBEY_DERIVED/Build/Products/Release/Robey Voice.app"
ROBEY_RECORD="$ROBEY_DERIVED/robey-build-record.json"
make local LOCAL_DERIVED_DATA="$ROBEY_DERIVED" LOCAL_CODESIGN_IDENTITY="$ROBEY_SIGNING_IDENTITY"
xcodebuild -project "$PWD/VoiceInk.xcodeproj" -scheme VoiceInk -configuration Release \
  -derivedDataPath "$ROBEY_DERIVED" \
  -clonedSourcePackagesDirPath "$PWD/.local-dependencies/SourcePackages" \
  -packageCachePath "$PWD/.local-dependencies/PackageCache" \
  -onlyUsePackageVersionsFromResolvedFile -disableAutomaticPackageResolution \
  -xcconfig "$PWD/LocalBuild.xcconfig" CODE_SIGN_IDENTITY="$ROBEY_SIGNING_IDENTITY" \
  CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=YES ARCHS=arm64 ONLY_ACTIVE_ARCH=YES \
  OTHER_CODE_SIGN_FLAGS=--timestamp CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
  -skipPackagePluginValidation -skipMacroValidation build
./scripts/verify-app.sh "$ROBEY_APP"
python3 scripts/validate-dependencies.py
python3 scripts/build-provenance.py finish "$ROBEY_RECORD" "$ROBEY_APP"
ROBEY_VOICE_APP="$ROBEY_APP" make test
```

Before submission, inspect every included Mach-O signature and architecture for the intended Developer ID, secure timestamp and hardened runtime, and verify that `get-task-allow` is absent or false. Signature verification alone does not establish those properties or Apple acceptance. The build record is refreshed only after the distribution signing and verification; any later app change needs a new binding and appropriate verification.

The signed disk-image route used for this release prepares a new package without submission, explicitly signs the outer DMG, saves the submission ID, then waits for that same submission. `scripts/release.sh --notary-profile <profile>` can submit a prepared Developer ID app's DMG and staple an Accepted ticket, but it does **not** sign the outer DMG itself. The explicit route below preserves that additional signing step:

```bash
ROBEY_PACKAGE="$PWD/.review-build/notarized-package-new"
ROBEY_DMG="$ROBEY_PACKAGE/Robey-Voice-0.1.0-arm64.dmg"
ROBEY_VOICE_BUILD_RECORD="$ROBEY_RECORD" ./scripts/release.sh --app "$ROBEY_APP" --output-dir "$ROBEY_PACKAGE"
codesign --force --sign "$ROBEY_SIGNING_IDENTITY" --timestamp "$ROBEY_DMG"
xcrun notarytool submit "$ROBEY_DMG" --keychain-profile "RobeyVoice-Notarization" \
  --output-format json > "$ROBEY_PACKAGE/notarization-upload.json"
ROBEY_SUBMISSION_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["id"])' "$ROBEY_PACKAGE/notarization-upload.json")"
xcrun notarytool wait "$ROBEY_SUBMISSION_ID" --keychain-profile "RobeyVoice-Notarization" \
  --output-format json > "$ROBEY_PACKAGE/notarization.json"
python3 -c 'import json,sys; assert json.load(open(sys.argv[1]))["status"] == "Accepted"' "$ROBEY_PACKAGE/notarization.json"
xcrun notarytool log "$ROBEY_SUBMISSION_ID" --keychain-profile "RobeyVoice-Notarization" "$ROBEY_PACKAGE/notarization-log.json"
xcrun stapler staple "$ROBEY_DMG"
xcrun stapler validate "$ROBEY_DMG"
hdiutil verify "$ROBEY_DMG"
spctl --assess --type open --context context:primary-signature --verbose=4 "$ROBEY_DMG"
spctl --assess --type exec --verbose=4 "$ROBEY_APP"
python3 scripts/build-provenance.py verify "$ROBEY_RECORD" "$ROBEY_APP"
```

Stop and inspect the saved log on rejection; if a command is interrupted, query the saved submission ID before submitting again. Stapling here changes the disk image, not the app. It does not establish offline app launch or second-Mac compatibility.

Only after the Accepted result and verification, update `DISTRIBUTION-STATUS.txt` to describe the observed result and regenerate `SHA256SUMS.txt` over the actual files to be distributed, including notarization receipts and the signing recipe when supplied. Signing/stapling changes the DMG hash, so the preparation script's earlier checksum file is stale. Keep the checksum file itself out of its input list. Never place passwords, private keys or credential exports in source or release assets.

The [notarized 0.1.0 release notes](docs/robey-voice-release-0.1.0-notarized.md) record the actual submission and validation checkpoint. `scripts/setup-release-notarization.sh` explains prerequisites only; it creates no account or credentials. There is no `make release-setup` target.

## Troubleshooting

- Complete Xcode's supported first-launch setup if developer framework loading fails.
- Install CMake or set `ROBEY_VOICE_CMAKE` if native preparation reports it missing.
- Preserve a mismatched native checkout/framework for inspection; use a separate checkout or explicitly rebuild after identifying the mismatch. Do not silently change the pin.
- Set `LOCAL_CODESIGN_IDENTITY` when several identities exist. Rebuilds, especially ad-hoc builds, can require normal macOS permission approval again.
- `make clean` only reports preserved output locations. It does not delete dependency caches or build products. Remove only selected generated directories after confirming no build is using them.

The [validation record](docs/robey-voice-validation.md) lists unresolved acceptance gates. Source checks alone do not certify an installable release.
