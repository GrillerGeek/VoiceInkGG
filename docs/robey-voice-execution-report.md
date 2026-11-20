# Robey Voice execution report

Saved November 18, 2026, from the November 17 build and validation checkpoint. Branch: `Customize`. Baseline: `b5d1be9a7c7377dd059f37bb3e0f791b802d4001`.

Robey Voice 0.1.0 is implemented as an independently branded local dictation fork with no application trial, activation, purchase, account, subscription, or commercial device-count dependency. The final Apple Development-signed arm64 Release build and all **22 acceptance checks passed**, with no skips. A verified local DMG and matching source package are prepared. Closing technical review returned **PASS** against E1–E12, EC1–EC10, B1–B9, and D1–D6, with the explicitly pending owner and device acceptance below.

This is a working local review deliverable, not a notarized distribution or evidence of installation on every computer. Earlier builds completed actual Apple Speech and Whisper file transcription with persistence; native validation of the latest model-recovery corrections was limited by unavailable app windows.

## Review materials and outputs

- [Execution plan, checklist, assumptions, and evidence](guildhall/plans/2026-11-16-robey-voice.md)
- [Closing technical review](robey-voice-closing-review.md)
- [Validation record and remaining checks](robey-voice-validation.md)
- [Installation, settings transfer, and rollback](robey-voice-installation.md)
- [Build instructions](../BUILDING.md)
- [Original branding preview](../.review-build/branding/brand-review.png) and [editable waveform artwork](../branding/robey-voice.svg)
- [Local DMG](../.review-build/review-package/Robey-Voice-0.1.0-arm64.dmg)
- [Source archive](../.review-build/review-package/Robey-Voice-0.1.0-source.tar.gz), [source provenance](../.review-build/review-package/source-provenance.json), [build record](../.review-build/review-package/build-record.json), and [package checksums](../.review-build/review-package/SHA256SUMS.txt)

The app is at `.review-build/DerivedData/Build/Products/Release/Robey Voice.app`. Generated artifacts and evidence remain in ignored workspace storage. The [local PR draft](robey-voice-pr-draft.md) is saved for review. Final source-only archive, provenance, and checksum verification is tracked in the [execution plan](guildhall/plans/2026-11-16-robey-voice.md) and [package checksums](../.review-build/review-package/SHA256SUMS.txt); it preserves the frozen app and DMG. No commit, push, PR publication, or public release was performed.

## Decisions and implementation

Jason authorized autonomous implementation, specialist delegation, and branding choices for later review. The [plan's assumptions](guildhall/plans/2026-11-16-robey-voice.md#assumptions-and-decisions-made-for-jason) are the detailed record. The principal choices were Robey Voice, version 0.1.0, teal/mint waveform branding, Apple silicon first, local recognition with enhancement and sensitive context off in fresh defaults, manual updates, and isolated storage rather than automatic upstream migration.

- Removed commercial enforcement types, trial and license navigation, purchase messages, and delivered-text prefixes in every configuration. Unlimited access does not depend on a local-build compilation flag.
- Removed upstream updater feed/key, announcement initialization, promotional flows, and CloudKit/APNs dependencies. Updates use explicit app replacement.
- Centralized identity under `com.jasonrobey.RobeyVoice`, with `.dev` for Debug. Application Support, defaults, device-local Keychain, model caches, custom sounds, and logging use the fork identity. The internal project/scheme/module remains VoiceInk.
- Preserved versioned settings transfer while excluding newly exported API secrets, trial state, and machine permission state. Existing explicit imports remain supported. Upstream data and credentials are neither automatically read nor moved or deleted.
- Preserved operational bounds and optional deliberately configured providers. Their external service costs and data handling remain their own; removing the app's commercial checks does not remove provider charges.
- Added bounded streaming Whisper GGML validation before discovery/import/download readiness, including supported vocabulary counts, full tensor inventory/types/shapes/extents, aggregate metadata limits, and cancellation. Invalid existing files remain available for inspection/reimport; failed native loading withdraws readiness.
- Added a persisted FluidAudio setup-readiness latch before setup begins. Interruption, failure, or cancellation remains not ready after restart; only verified native success clears the marker, with Resume Download offered for recovery.
- Pinned clean dependency revisions and workspace-owned caches, verified the real app and nested binaries, bound build inputs to the app tree, and produced a manual package with source provenance and checksums.

The application remains [GPLv3](../LICENSE), with original copyrights and attribution preserved. The separately licensed VoiceInk Refine model is unavailable because its exact pinned terms restrict use in other software and redistribution without permission; the application's GPL does not grant rights to that model. The inactive Refine helper and related dependencies are excluded from the app build. The original tracked MIT-licensed Silero VAD detector is preserved with exact checksum and provenance; no newly downloaded transcription or Refine weights are included in source or package. See [third-party notices](../THIRD_PARTY_NOTICES.md) and the [exact dependency inventory](../VoiceInk/Resources/Legal/DEPENDENCY_INVENTORY.md).

## Verification and review

The independent original suite established meaningful RED before implementation, followed by GREEN without implementer edits to accepted tests. A separate contrast regression caught the mint/white foreground issue before correction; measured Aqua and Dark Aqua body-label ratios now exceed 4.5:1. All nine accepted test files retain their frozen hashes in the plan and validation record.

Closing review initially returned BLOCKED for EC4: inherited Whisper discovery could mark an arbitrary `.bin` ready before native failure. Independent model tests established RED, then the streaming validator repaired that contract. Narrow security review found an additional coherent unsupported-vocabulary case; a separate regression failed meaningfully before the native-supported bounds were applied. The complete provider audit then found FluidAudio's failed-setup state could be lost on restart; an independent cross-process store test established RED before the persistent latch repair. Narrow security and reliability refreshes passed, and closing technical review returned PASS after the final build and evidence refresh.

Final automated and artifact evidence:

| Check | Observed result |
| --- | --- |
| Release build | `BUILD SUCCEEDED`, exit 0, standard `.review-build/DerivedData` |
| Complete artifact suite | 22 tests, no skips, **29.538 seconds**, `.review-build/acceptance-artifact.log` |
| App and embedded signatures | Deep/strict and individual Mach-O checks passed outside the restrictive sandbox |
| Architectures | App, whisper, MediaRemoteAdapter: arm64; CTranscribe: arm64 and x86_64; no whole-app Intel claim |
| Dependency and legal inventory | Nine exact clean Swift package checkouts plus native whisper.cpp; 16 retained dependency license files |
| Package | Release exit 0, all five checksum entries passed, DMG integrity VALID, staged app identical to the tested app, staged signatures passed |
| Source package | Archived files matched source provenance; no private fixtures, newly downloaded model weights, dependency caches, symlinks, or credentials included |

Final source-input digest:

```text
da441f50e8d7d07538eb77a1c00e3f066c5cca56b3c730e2479cfe5dd7192804
```

Final app-tree digest:

```text
e5a6dca2c17410c752e7aa1acdda0515b625fd81ef166c705432c91629f5c22a
```

Final `Robey-Voice-0.1.0-arm64.dmg` SHA-256:

```text
e052fa52a51aa56f5415beef584c69a15d89d0260624960cdd1ab63b1e0df895
```

Security, reliability, performance, observability, operations, accessibility, documentation, native UI, and closing architecture/technical reviews were selected. Migration/isolation was covered through source, security, reliability, and operations review; no SQL/schema migration required a separate migration execution. Browser Playwright checks were inapplicable to this native Swift app, and plugin validation was skipped because no plugin package changed. Review coverage does not convert missing native or human checks into passes.

The pre-existing [repository review](2026-11-16-repository-review-and-customization-plan.md) was preserved. No existing upstream data, private recording, or API credential was used as a fixture. Generated dependencies, model downloads, build products, synthetic audio, and runtime logs remain excluded from tracked source.

## Native evidence and cleanup

Earlier signed builds showed branded onboarding with Continue disabled until permission approval, imported the checksummed Tiny English model, and created a task-owned Local Dictation mode with enhancement off. Actual Apple Speech and Whisper file transcription returned the exact expected sentence, without a commercial prefix or account prompt, and both results persisted after quit/relaunch. The corrected model picker exposed its accessible label, selected value, and stable identifier and worked through native AX interaction.

The seven-second audio was generated Samantha text-to-speech, not an ambient microphone recording or private file. The original valid model and two synthetic history records remain in the isolated fork data for review. The file-transcription walkthrough temporarily seeded the fork-only onboarding preference; it did not complete normal permission onboarding.

After the model-validation repair, CUA window access failed for both Robey Voice and Finder with `cgWindowNotFound`, including a supported Finder new-window attempt. Running-app inventory did not establish a crash. Latest invalid-file discovery/import, recovery UI, and large FluidAudio setup were therefore unverified; no alternate UI bypass was used. The second onboarding seed was restored to its originally absent state, an unchanged task-only invalid discovery probe was removed after exact-content verification, and only the task-launched process was stopped and confirmed stopped. The app is closed. No Microphone/Accessibility permission was granted and no TCC or system-security policy was changed.

## Remaining owners and acceptance

- **Jason:** review the name/icon/theme and daily-use experience; grant needed permissions through normal macOS flows; verify microphone capture, shortcuts, paste/clipboard restoration, and representative applications.
- **Jason with the next native validation session:** repeat valid transcription and invalid-file discovery/import/recovery on the latest app; exercise interrupted download, cancellation, restart, Resume Download, offline operation, and a large FluidAudio setup. Full keyboard/VoiceOver/focus and destructive/system-red contrast remain informational accessibility checks.
- **Application maintenance:** low-priority observability follow-up for an imported Refine mode launched by shortcut degrading to plain text without a per-operation reason. Dashboard/editor warnings exist; add bounded status/logging without transcript contents if this path is retained.
- **Jason/distribution maintainer:** supply a usable Developer ID Application identity and notarization profile for ordinary independent distribution, then perform the actual accepted submission/ticket checks. The available Apple Development signature is not notarization.
- **Jason on another compatible Mac:** verify installation/Gatekeeper acceptance, permissions, model setup, transcription, and data preservation. Intel, macOS 15 hardware behavior, lower-memory variants, production replacement, transfer/coexistence, and rollback remain distinct acceptance work.

The saved closing review, this execution report, and the [local PR draft](robey-voice-pr-draft.md) accompany the frozen app and DMG. Final source archive, provenance, and checksum verification is recorded in the execution plan and package checksums. Human branding approval, real-device acceptance, notarization, and second-Mac acceptance remain explicitly open.
