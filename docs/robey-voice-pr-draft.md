Create Robey Voice with unlimited local dictation

## Summary

- Remove app trials, activation, purchase prompts, commercial device limits and transcription prefixes; replace upstream updates and announcements with manual installation.
- Brand the fork as Robey Voice, isolate its storage and credentials, and default to local recognition with enhancement and sensitive context off. Preserve GPL attribution and notices; disable the separately restricted VoiceInk Refine model.
- Add model-readiness validation and persistent setup recovery, pin dependencies, and produce a signed Apple silicon app/DMG with matching source provenance and checksums.

## Plan reference

[Robey Voice specification, checklist, assumptions and evidence](docs/guildhall/plans/2026-11-16-robey-voice.md)

## Test plan

- [x] Establish meaningful independent failures before implementation and preserve all nine frozen test files.
- [x] Build the real Release app and pass all 22 acceptance checks, with no skips, in 29.538 seconds.
- [x] Verify Debug/Release identity isolation, removed commercial dependencies, absent upstream update configuration, exact package revisions and light/dark accent contrast.
- [x] Accept the checksummed Tiny English model and reject corrupt, truncated and unsupported-vocabulary containers; verify setup retry state across separate processes.
- [x] Verify app/component architectures and signatures, DMG integrity, staged-app equality, source provenance and package checksums.
- [x] Complete independent specialist reviews and closing technical review: PASS.
- [x] Observe actual Apple Speech and Whisper synthetic file transcription and history persistence in earlier signed builds; restore temporary test state.
- [ ] Repeat valid transcription and invalid-model discovery/import/recovery in the latest repaired app when native window access is available.
- [ ] Complete normal permission onboarding, microphone dictation, paste/shortcuts and keyboard/VoiceOver acceptance.
- [ ] Exercise offline/fault scenarios, large FluidAudio interruption/resume, settings transfer, coexistence, replacement and rollback.
- [ ] Validate a second Mac and complete Developer ID/notarized distribution when credentials are available.

## Runbook

### Deploy plan

1. Use the final local package in `.review-build/review-package/`. From that directory, run `shasum -a 256 -c SHA256SUMS.txt` and `hdiutil verify Robey-Voice-0.1.0-arm64.dmg`; read `DISTRIBUTION-STATUS.txt`.
2. This artifact is Apple Development signed and not notarized. Target Apple silicon; macOS 15 is the deployment target. Intel, other hardware/OS combinations, and second-Mac installation are unverified. Normal independent distribution needs an available Developer ID Application identity and usable notarization credentials.
3. Quit Robey Voice, retain the previous app, export settings, and back up its complete Application Support directory before replacing an existing production build. Mount the DMG and copy `Robey Voice.app` into Applications using the installation runbook.
4. Have the owner complete normal Microphone and Accessibility approval. Current onboarding requires both, including for imported-audio navigation. No security bypass or permission database change is part of installation.
5. Install and select a permitted local transcription model. Keep enhancement and sensitive context off for plain local dictation. Apple Speech requires macOS 26; Whisper transcription weights download separately. VoiceInk Refine is unavailable under its separate model license.
6. No licensing flag, backend deployment, database migration, subscription credential, automatic update feed, or CloudKit setup is required. Updates are deliberate app replacements. Build and package commands are in `BUILDING.md`; direct custom-DerivedData packaging must supply its matching `ROBEY_VOICE_BUILD_RECORD`.

### What to watch (first hour)

- Launch and onboarding: the app opens under Robey Voice and explains pending permissions without trial, activation, or purchase prompts.
- Model readiness: the intended model is installed, selectable, and remains selected after saving and reopening its mode.
- Transcription: task-owned synthetic audio returns clean expected text with the selected local provider and enhancement off.
- Persistence and delivery: the result remains in History after relaunch; separately verify owner-approved live dictation, text insertion, and clipboard restoration.
- Resource and failure behavior: watch transcription duration, memory pressure, model errors, download retry states, and History/audio retention. Diagnostic entry points are Settings logs and Dashboard’s Copy System Info; inspect exported diagnostics before sharing.

### Rollback plan

Quit the new app and restore the retained previous `Robey Voice.app`. Do not delete Application Support merely to change versions.

If the previous app cannot read the resulting data, preserve the newer data separately and restore the matching pre-update Application Support backup while the app is stopped. Settings export alone does not back up history, recordings, model weights, or device-local Keychain credentials. Do not merge database files by hand. Normal macOS permission reapproval may be required.

Upstream VoiceInk is a separate application with separate data and credentials; leave it intact. Packaged replacement and rollback remain acceptance checks until exercised.

### On-call notes

The Release identity is `com.jasonrobey.RobeyVoice`; Debug uses `.dev`. Their preferences, Application Support, and device-local Keychain namespaces are separate. No automatic upstream data migration occurs.

A missing local model needs installation or retry, not a license. Optional cloud providers require deliberate configuration and may charge separately. Imported Refine selections need plain dictation or a permitted provider. The recorded low observability follow-up concerns per-operation explanation of Refine shortcut fallback; owner: application maintenance.

The verified synthetic tests used temporary seeded navigation without granting Microphone or Accessibility. That onboarding seed was removed, normal permission onboarding was observed again, and the app was quit. Two synthetic results and the task-created local mode/model remain in isolated fork data.

Build/source binding failures require investigation and a matching rebuild, rather than copying another record. `make clean` intentionally preserves generated outputs and caches.

### Open ops questions

- Jason must accept branding and daily-use behavior, complete permission onboarding, and verify live microphone dictation and app-wide paste.
- A second Mac must validate ordinary launch, model setup, transcription, permission behavior, replacement, and data preservation. Developer ID/notarization prerequisites are currently absent.
- Disconnected operation, interrupted/invalid download recovery, broader cancellation/failure behavior, settings transfer/rollback, and full keyboard/VoiceOver acceptance remain explicitly unverified.
- This personal desktop app has no service dashboard, paging integration, rollout percentage, or stated service SLO. The initial rollout is owner review on one Mac before deliberate installation elsewhere.

## Reviewer notes

This draft describes the complete uncommitted working tree, including new source, tests, legal resources, branding and documentation. There are no commits after baseline `b5d1be9a7c7377dd059f37bb3e0f791b802d4001`. The pre-existing repository review document is preserved. No push, PR creation or public release was performed.

The latest app and DMG are frozen and Apple Development signed, not notarized. The main app is arm64; macOS 15 is its deployment target, while Apple Speech requires macOS 26. An x86_64 slice in CTranscribe does not establish whole-app Intel support.

Earlier signed builds completed actual Apple Speech and Tiny English Whisper file transcription with persistent history. After the model-readiness repairs, native window acquisition failed for both Robey Voice and Finder with `cgWindowNotFound`; no crash was established. The latest repaired UI remains unverified. Temporary onboarding preferences, the task-only invalid discovery probe and the task-launched process were cleaned up and checked.

The application retains GPLv3 and upstream attribution. VoiceInk Refine is unavailable under its separate model license. The original MIT Silero VAD model is retained with verified provenance; downloaded transcription weights and private/runtime fixtures are excluded from source packages.

Remaining review follow-ups:

- **Low — application maintenance:** explain per-operation fallback when an imported Refine mode invoked by shortcut degrades to plain text; dashboard/editor warnings already exist.
- **Informational — application accessibility maintenance/Jason:** verify semantic system-red contrast, focus/pressed states and complete VoiceOver navigation.

Open items for the user, verbatim from the plan:

- Review the Robey Voice name, teal waveform icon and theme.
- Approve normal macOS Microphone and Accessibility permissions, then validate microphone dictation and paste/shortcuts. No permission grants were made unattended.
- For routine distribution to other Macs, provide a usable Developer ID Application identity and notarization profile, then build/notarize and perform a normal second-Mac installation. This review artifact is Apple Development signed and not notarized.
- Confirm hardware targets beyond the verified Apple silicon host; Intel, macOS 15 hardware, lower-memory configurations, and full VoiceOver/focus acceptance remain unverified.

### How to create this PR

After reviewing, committing and pushing the branch, save this body starting at `## Summary` to a body-only file, then run: `gh pr create --draft --title "Create Robey Voice with unlimited local dictation" --body-file <body-file>`
