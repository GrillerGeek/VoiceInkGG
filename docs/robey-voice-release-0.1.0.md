# Robey Voice 0.1.0 preview

Release preparation: November 20, 2026. Target tag: `v0.1.0`. The release operator verifies the commit, merge, tag and uploaded assets when publishing; this document does not itself establish that publication occurred.

[Release and downloads](https://github.com/GrillerGeek/VoiceInkGG/releases/tag/v0.1.0)

This first Robey Voice preview removes the application's trial, license activation, purchase prompts, commercial device limits and delivered-text prefixes. It introduces the Robey Voice name and waveform artwork, isolated app data and device-local credentials, local defaults with enhancement and sensitive context off, and deliberate manual updates without upstream feeds or announcements.

Whisper model discovery, import and download now validate supported complete containers before readiness. FluidAudio setup retains its retry requirement across interruption, failure and relaunch, offering Resume Download until native setup succeeds. Existing model files are preserved for recovery.

## Requirements and signing

- **Apple silicon; macOS 15 or later is the deployment target.** Intel, lower-memory configurations and actual macOS 15 hardware remain unverified. Apple Speech additionally requires macOS 26 or later.
- **Apple Development signed, not notarized.** This is a preview for owner review, not a claim of ordinary independent distribution or second-Mac acceptance. Normal distribution needs a usable Developer ID Application identity and notarization credentials. Do not disable Gatekeeper or change security databases to install it.
- Install a permitted transcription model and its required assets before offline use. Microphone and Accessibility approval must use normal macOS flows; current onboarding requires both. Local dictation has no app subscription or account requirement. Optional cloud services retain their own charges and data handling.

## Assets and verification

Download all six assets from the same release into one directory:

- `Robey-Voice-0.1.0-arm64.dmg`
- `Robey-Voice-0.1.0-source.tar.gz`
- `source-provenance.json`
- `build-record.json`
- `DISTRIBUTION-STATUS.txt`
- `SHA256SUMS.txt`

Then run:

```bash
shasum -a 256 -c SHA256SUMS.txt
hdiutil verify Robey-Voice-0.1.0-arm64.dmg
```

The reviewed DMG's SHA-256 is `e052fa52a51aa56f5415beef584c69a15d89d0260624960cdd1ab63b1e0df895`. The matching source archive and provenance include the committed publication documentation; their current hashes are in `SHA256SUMS.txt`. The app/DMG remain the tested binaries.

## Validation and limits

The reviewed Release app passed **22 acceptance checks with no skips in 29.538 seconds**, including real artifact identity, architecture and signature checks, model validation and persistent setup readiness. Package integrity, staged-app equality and source/app build binding were verified. Closing technical review passed for the bounded local review scope.

Earlier signed builds completed actual Apple Speech and Whisper synthetic file transcription and retained history after relaunch. Native window access later became unavailable for both the app and Finder, so those observations do not certify the latest model-recovery UI. Temporary task preferences, probe files and the task-launched process were cleaned up.

Remaining acceptance includes the latest valid/invalid model import and recovery UI; large FluidAudio interruption/resume; offline and fault scenarios; full permission onboarding and denial/recovery; live microphone dictation, paste and shortcuts; settings transfer, coexistence, replacement and rollback; full keyboard/VoiceOver/focus behavior; branding and daily use; and installation on another Mac. No new permission grant, notarization or second-Mac success is claimed by this preview.

See the [validation record](https://github.com/GrillerGeek/VoiceInkGG/blob/v0.1.0/docs/robey-voice-validation.md), [installation and rollback runbook](https://github.com/GrillerGeek/VoiceInkGG/blob/v0.1.0/docs/robey-voice-installation.md), and [execution plan and assumptions](https://github.com/GrillerGeek/VoiceInkGG/blob/v0.1.0/docs/guildhall/plans/2026-11-16-robey-voice.md).

## Licensing

The application retains GPLv3, original VoiceInk authorship and selected dependency/model notices. The separately restricted VoiceInk Refine model is unavailable; the application's license does not grant rights to it. The original MIT-licensed Silero VAD detector is preserved with verified provenance. No newly downloaded transcription or Refine weights, private audio, runtime fixtures, credentials or dependency caches are bundled in the source package.
