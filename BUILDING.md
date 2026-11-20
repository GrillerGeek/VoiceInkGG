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

Only when an appropriate Developer ID Application identity and an existing Keychain notarization profile are available, build with that identity and pass `--notary-profile <profile>` to `scripts/release.sh`. The script requires a Developer ID app, submits the DMG, requires an Accepted result, and staples and validates its ticket. `scripts/setup-release-notarization.sh` only explains prerequisites; it creates no account or credentials. There is no `make release-setup` target. Current credentials are insufficient for notarization; a local package must be labeled accordingly.

## Troubleshooting

- Complete Xcode's supported first-launch setup if developer framework loading fails.
- Install CMake or set `ROBEY_VOICE_CMAKE` if native preparation reports it missing.
- Preserve a mismatched native checkout/framework for inspection; use a separate checkout or explicitly rebuild after identifying the mismatch. Do not silently change the pin.
- Set `LOCAL_CODESIGN_IDENTITY` when several identities exist. Rebuilds, especially ad-hoc builds, can require normal macOS permission approval again.
- `make clean` only reports preserved output locations. It does not delete dependency caches or build products. Remove only selected generated directories after confirming no build is using them.

The [validation record](docs/robey-voice-validation.md) lists unresolved acceptance gates. Source checks alone do not certify an installable release.
