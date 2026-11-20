# Robey Voice validation record

Checkpoint: November 17, 2026. Baseline: `b5d1be9a7c7377dd059f37bb3e0f791b802d4001`, branch `Customize`. This records the current working tree, including uncommitted implementation and new source files. The pre-existing [repository review](2026-11-16-repository-review-and-customization-plan.md) is preserved as historical context. The [standalone specification and execution evidence](guildhall/plans/2026-11-16-robey-voice.md) define the acceptance requirements.

The latest Apple Development-signed Release app built and passed all 22 acceptance checks, including the two real artifact checks and new invalid-model/setup-readiness regressions. Earlier signed builds completed actual local Apple Speech and Whisper file transcription with saved history after relaunch. Native window access subsequently became unavailable, so those earlier observations do not certify the latest model-validation and setup corrections in the UI. The latest build uses `.review-build/DerivedData`. The unused `FinalDerivedData` build request was aborted and supplies no evidence. No notarization or second-Mac acceptance is claimed.

The documentation writer inspected the saved build, artifact-test, model, and fixture evidence and used the orchestrator's actual native UI observations and package verifier's results. The writer ran no builds or tests. Runtime logs and synthetic fixtures stay in ignored `.review-build/`; no local screenshot files were saved or claimed.

## Recorded Results

| Check | Result and evidence | Limit |
| --- | --- | --- |
| Independent accepted baseline | 11 tests: 7 assertion failures, 2 passes, 2 real-artifact skips, 0 errors; recorded in the execution plan | Establishes meaningful RED for the changed contract |
| Original suite after implementation | 11 tests: 9 passes, 2 real-artifact skips; original files retain accepted hashes | Source/configuration and isolated identity checks |
| Final real Release build | `.review-build/release-build.log` contains `BUILD SUCCEEDED`, successful signature checks, nine exact clean Swift package checkouts, and completed source/app digest binding | Applies to `.review-build/DerivedData/Build/Products/Release/Robey Voice.app` |
| Combined suite against latest app | `.review-build/acceptance-artifact.log`: 22 tests passed, no skips, 29.538 seconds; includes both real Release artifact tests | Source/configuration, identity, contrast, model validation/readiness, and actual artifact checks; native behavior is recorded separately |
| Final app architectures/signature | Main app, whisper, and MediaRemoteAdapter: arm64. CTranscribe: arm64 and x86_64. Apple Development deep/strict and individual Mach-O signatures verified | Entire app is an arm64 build; an Intel slice in one dependency does not establish Intel support or notarization |
| Swift source checks | Orchestrator reports full Swift frontend parse and isolated identity/Keychain/manual-updater/About typechecks passed | Does not compile or link the full app or all dependencies |
| Native Whisper dependency | arm64 macOS 15 framework built from whisper.cpp v1.8.3, revision `2eeeba56e9edd762b4b38467bab96c2517163158`, with Metal and CoreML; local evidence: `.review-build/whisper-build.log` | Dependency result, not app transcription evidence |
| Signing prerequisites | One Apple Development identity found; no Developer ID identity; no saved credentials for the checked RobeyVoice/upstream-named notary profiles; local evidence under `.review-build/baseline/` | Local signing is possible; notarized independent distribution is unavailable with discovered credentials |
| Branding | Original waveform assets and preview generated; orchestrator viewed 16–256 px light/dark review sheet | Implementation visual QA only; Jason's acceptance pending |
| Source security/reliability reviews | Independent reviews recorded no introduced security or reliability findings within their source scopes | Source review is distinct from package and native validation |
| Third-party notices | Exact-revision inventory now verifies all ten entries: nine resolved Swift packages and native whisper.cpp, with retained notices; no pending checkout entries | Selected optional model notices do not clear the entire catalog, custom models, or future downloads |
| Whisper CLI inference | Valid synthetic WAV and pinned Tiny English model produced the expected word sequence; `.review-build/fixtures/validation.json` and `whisper-cli.log` record the result | Punctuation/line breaks differed; CoreML encoder was absent, so this confirms successful fallback inference rather than CoreML execution |
| Earlier native app workflows | Orchestrator observed Tiny English import/downloaded state, Apple Speech transcription, and Tiny English Whisper transcription; both full results persisted after quit/relaunch | Observed before the latest model-validation/setup repairs; seeded file navigation, no Microphone or Accessibility grant or live dictation |
| Earlier picker verification | Native AX exposed `Transcription Model`, its selected value, and `transcription-model-picker`; selection and saving worked | Observed before the latest repairs; complete VoiceOver/focus and permission recovery remain owner checks |
| Latest local review package | `.review-build/review-package/`: release exited 0, all five checksum entries passed, DMG integrity VALID, staged app matched the latest built app exactly, and staged signatures passed. Source archive file hashes matched its provenance, with 16 dependency license files and the original MIT VAD; no private fixtures, newly downloaded weights, caches, symlinks, or credentials were included | Apple Development signed, not notarized; no second-Mac installation or extracted-source build claimed. Source archive/provenance/checksums are refreshed after final documentation/report outputs; the app and DMG remain unchanged |
| Latest build binding | Source digest `da441f50e8d7d07538eb77a1c00e3f066c5cca56b3c730e2479cfe5dd7192804`; app-tree digest `e5a6dca2c17410c752e7aa1acdda0515b625fd81ef166c705432c91629f5c22a` | Source archive provenance separately records documentation and other reviewed source outputs |
| Invalid Whisper models | Independent real-model/native CPU calibration passed; validator checks passed for the real Tiny model and corrupt/truncated/header/tensor cases. A separate coherent unsupported-vocabulary case failed meaningfully before the guard was tightened, then passed | Automated validator coverage; latest native discovery/import/retry UI unverified |
| Setup readiness across restart | Independent cross-process store test passed in 2.435 seconds, using isolated UUID defaults domains and scoped cleanup. Narrow security/reliability refresh passed for parser and persisted setup latch | Store/source evidence; no large FluidAudio download, cancellation, restart, and resume UI walkthrough claimed |
| Latest session cleanup | Temporary onboarding key restored to absent; unchanged task-only invalid discovery probe removed and absence confirmed; only the task-launched app process was stopped and confirmed stopped | Native windows were unavailable, so this is cleanup evidence rather than latest UI success |

The final `Robey-Voice-0.1.0-arm64.dmg` SHA-256 is `e052fa52a51aa56f5415beef584c69a15d89d0260624960cdd1ab63b1e0df895`. The source archive has its own package manifest and checksums; its hash changes when closing documentation is included.

Frozen acceptance source SHA-256 values supplied by root:

- `identity_main.swift`: `8d7b8a5f5b6f79a4b2964b2d7b77e31a3b9cccb758fdb237d6cdd0e4337b277d`
- `test_personal_fork.py`: `60dd0fadd7a743147ca8d4e0bbf46510ce1cc651be548e03c1661a38aad3af50`
- `test_brand_contrast.py`: `8ec3176ba2a9dc667aaca61b6a5f8411fe3e6d18f68a9c8e5827668e17ea4350`
- `contrast_main.swift`: `beb9b8fb6da693e4bd204bf4a7fe13b4126d821747d88647b24a9b012675dd68`
- `test_whisper_model_validation.py`: `ed5d50fd4c4412c3d0a9e90f2328c16f9e03319f3cbf5add062b48d3fd128c86`
- `whisper_validation_main.swift`: `6fb1bd6d7b2bea727280b17aff5d4df9cc5dbe16f580af905187015788ecfb58`
- `test_whisper_vocabulary_bounds.py`: `4b38f6424dc735bed2d40c5f3107d685f39e67222d08a5c982b22bbe0249f2ec`
- `test_model_setup_readiness.py`: `ed65570fc3023d214300e80e961cc05a31e516236bc1b12edbc704ea14d88fc1`
- `model_setup_readiness_main.swift`: `753f0ab6a727ea792ad09866c5e4bd103afbf99f91fc3587f8cf6bfd6b79f9bd`

All nine files are under `Tests/PersonalForkAcceptance/`. The separate contrast suite compiles the real theme as an opaque Swift input and checks body-label contrast against the configured Aqua and Dark Aqua accents, with reference fixtures and a calibrated native appearance bridge. Root recorded Aqua **5.932228:1** with white foreground and Dark Aqua **9.988459:1** with ink foreground (sRGB 0.063/0.165/0.208). These exceed the 4.5:1 body-label requirement. The result does not establish keyboard focus, pressed states, VoiceOver navigation, or complete app accessibility.

## Source Evidence

- `Shared/AppIdentity.swift` supplies distinct Debug/Release bundle, storage, Keychain, and log identities. Project configuration uses Robey Voice version 0.1.0 while retaining the VoiceInk module and scheme.
- Commercial enforcement types and license UI are removed. Delivery no longer checks trial or activation state. These source checks do not replace fresh/expired-state or long-running native acceptance.
- The updater presents manual installation information; upstream feed/public key, announcement initialization, promotional flows, CloudKit/APNs entitlements, and dictionary CloudKit configuration are removed.
- Fresh defaults leave enhancement, automatic correction observation, and sensitive context off. Explicit saved/imported settings remain honored. Keychain is device-local and isolated; no automatic upstream credential/data migration is implemented.
- VoiceInk Refine download and execution are unavailable because its exact pinned model license restricts this fork. The inactive helper and related package products are excluded from the app build. Optional permitted providers remain deliberate choices.
- Build scripts use workspace-owned native/package caches and exact clean package resolution. Native framework reuse checks a revision/options marker. Source/resource hashes and the resulting app tree are bound in a build record and checked again before packaging. Transcription weights are separate downloads; mutable model URLs remain a documented provenance limit.
- `Shared/WhisperModelValidator.swift` streams the supported GGML model format and validates metadata, complete tensor inventory, types, shapes, and payload extents. Vocabulary is limited to native-supported counts 51864, 51865, and 51866, with an 8 MiB aggregate token-metadata budget and cancellation checks. Discovery, import, and download use the validator before readiness; invalid files remain available for inspection/reimport, and failed native loading removes readiness.
- `ModelSetupReadinessStore` persists FluidAudio's not-ready setup latch before work starts. Failed, interrupted, or cancelled setup remains not ready across restart; verified native success is required to clear the marker. The manager and card offer Resume Download. This does not promise integrity monitoring for arbitrary external modifications after discovery.
- The existing bundled `VoiceInk/Resources/models/ggml-silero-v5.1.2.bin` VAD detector is preserved: 885,098 bytes, SHA-256 `29940d98d42b91fbd05ce489f3ecf7c72f0a42f027e4875919a28fb4c04ea2cf`. Its exact GGML conversion is `9ffd54a1e1ee413ddf265af9913beaf518d1639b`; original Silero v5.1.2 source is `6478567951ae5c9979ad7b234185b5515f4be7a1`. The retained MIT license and model card identify both. No newly downloaded transcription or Refine weights enter source review packages.

## Synthetic Audio and Native Walkthrough

The valid test fixture is macOS Samantha text-to-speech generated directly to a file, with no microphone recording or playback: `.review-build/fixtures/local-transcription.wav`, 112,916 samples at 16 kHz, duration **7.05725 seconds**, SHA-256 `e764d9389656f944dc3c827d3e4ae8c6e309dc4958cb484866983007b5893507`. An earlier empty audio attempt was rejected and supplies no transcription evidence.

The downloaded Tiny English Whisper model has SHA-256 `921e4cf8686fdd993dcd081a5da5b6c365bfde1162e72b08d75ac75289920b1f`, matching the pinned pointer at `ggerganov/whisper.cpp` revision `5359861c739e955e79d9a303bcbc70fb988958b1`. CLI inference through native whisper.cpp produced the exact expected word sequence with punctuation and line-break differences. `.review-build/fixtures/validation.json`, `whisper-result.txt`, and `whisper-cli.log` retain the local result. CoreML was enabled at build time, but its optional model encoder was absent during this run and the supported fallback succeeded.

The orchestrator's actual native UI walkthrough observed:

1. The branded permissions screen displayed Continue disabled without Microphone or Accessibility grants.
2. The originally absent fork preference `hasCompletedOnboardingV2` was temporarily seeded true to reach file-import testing. This is seeded navigation, not completed permission onboarding.
3. Tiny English was imported through the actual model UI and displayed Downloaded. A default Local Dictation mode was created with enhancement off; Apple Speech was the initially selected transcription provider.
4. The actual Apple Speech file-transcription path processed the valid synthetic WAV and returned: “This is a local transcription test. The quick brown fox jumps over the lazy dog. No subscription is required.”
5. The result appeared in Saved History. After quit and relaunch, Recent Transcripts still contained the full text. No purchase prefix, license key, or app account was involved.
6. In the rebuilt app before the later model-validation/setup repairs, the corrected model picker exposed its accessible label, current value, and stable identifier. Local Dictation and the imported model remained available. Tiny (English) was selected and saved with enhancement off.
7. That app transcribed the same WAV through Tiny English Whisper and returned the exact text quoted above, including punctuation. After quit and relaunch, Recent Transcripts contained both the Whisper result and the earlier Apple Speech result.
8. After quitting, the temporary onboarding preference was deleted successfully, restoring the originally unset state. Relaunch showed the normal permission screen with Microphone Allow, Accessibility locked, and Continue disabled. The app was then quit and absent from the running-app inventory. The task-owned mode, imported model, and two synthetic transcripts remain in the isolated fork data for review.

These observations establish local native Apple Speech and Whisper file workflows and persistence before the latest repairs. They do not establish the latest repaired model setup UI, live microphone dictation, Accessibility paste, disconnected operation, or a complete permission-denial/recovery test. An earlier windowless app was reopened through Finder. Later, after the Whisper validation repair, both app and Finder window acquisition failed with `cgWindowNotFound`, including a supported Finder new-window attempt; running-app inventory did not establish a crash. No alternate UI bypass was used. The second temporary onboarding seed was restored to absent, a task-only invalid discovery probe was removed after exact-content verification, and only the task-launched review process was stopped. The app is closed; the original task-owned mode, Tiny model, and two synthetic history records remain isolated to the fork. Native tool observations are the evidence; no screenshots were written to local files.

## Reproduce Checks

From the repository root:

```bash
python3 -B -m unittest discover -s Tests/PersonalForkAcceptance -v
ROBEY_VOICE_APP="$PWD/.review-build/DerivedData/Build/Products/Release/Robey Voice.app" python3 -B -m unittest discover -s Tests/PersonalForkAcceptance -v
./scripts/verify-app.sh ".review-build/DerivedData/Build/Products/Release/Robey Voice.app"
```

The first command intentionally skips two artifact tests without `ROBEY_VOICE_APP`. The second requires a real Release app and checks its bundle/feed configuration, executable and embedded Mach-O architectures, and signatures. The separate script also prints linked libraries and signature details. A valid signature does not establish notarization or successful execution. Build and package commands are documented in [BUILDING.md](../BUILDING.md).

## Pending Acceptance and Review

- [x] Complete the latest Release rebuild under standard `.review-build/DerivedData`; all 22 acceptance checks passed and final architectures, signatures, and source/app binding were verified.
- [x] Confirm the final app includes the refreshed ten-entry dependency notices and exact bundled VAD provenance with the Legal resource hierarchy preserved.
- [x] Verify an earlier app's Whisper file-transcription route using the validated synthetic fixture and pinned Tiny English model; confirm saved output after relaunch.
- [ ] Repeat valid transcription and invalid-file discovery/import/recovery in the latest repaired app when native window access is available.
- [x] Verify the corrected model picker label/value and selection through native AX. About & Licenses branding/heading semantics were observed in the earlier app; source contrast checks passed for both appearances.
- [ ] Complete broader native review of model retry, manual update information, all legal resources, sidebar focus/selected semantics, and light/dark presentation.
- [x] Verify invalid Whisper containers and supported vocabulary bounds through independent tests; verify the FluidAudio readiness store across separate processes.
- [ ] Verify offline operation after assets are installed, optional enhancement failure recovery, and native interrupted/invalid download, cancellation, restart, and Resume Download flows, including a large FluidAudio setup.
- [ ] Exercise fresh/expired-state and clock-change behavior in native configurations without purchasing, activating, or reading upstream credentials.
- [ ] Exercise microphone/Accessibility denial and supported recovery with the owner present. Verify keyboard/VoiceOver behavior and text insertion/clipboard restoration in representative apps. Do not record ambient microphone audio unattended.
- [x] Produce and verify the local DMG, source snapshot, provenance, distribution status, checksums, staged-app equality, and packaged-app signatures. Notarization is unavailable with the discovered credentials.
- [ ] Test production replacement, settings export/import without new secrets, upstream coexistence, and rollback with synthetic data and backups.
- [ ] Validate installation, permissions, model setup, transcription, and data preservation on a second Mac. Intel and other hardware/OS combinations remain unverified.
- [ ] Obtain Jason's branding and daily-use acceptance after reviewing the concrete app and artwork.
- [x] Restore temporary onboarding preferences to their original unset state and close the task app. The normal permission screen was observed after the first cleanup; latest cleanup confirmed the key absent without claiming unavailable UI verification.

Current onboarding requires Microphone and Accessibility before completion, including for the file-import route. The walkthroughs used the documented temporary fork-only seed, now removed, and granted neither permission. No TCC database changes, Gatekeeper bypass, private recording fixtures, cloud transmission of private data, publication, or credential export is part of validation.
