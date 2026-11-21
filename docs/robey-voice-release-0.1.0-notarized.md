# Robey Voice 0.1.0 notarized preview

Notarization checkpoint: November 21, 2026. Publication target: `v0.1.0-notarized`.

[Notarized release and downloads](https://github.com/GrillerGeek/VoiceInkGG/releases/tag/v0.1.0-notarized)

This is a distribution-signing update of application version **0.1.0**, with the same application source and features as the original preview. The original [Apple Development-signed preview](https://github.com/GrillerGeek/VoiceInkGG/releases/tag/v0.1.0) remains unchanged. This separate preview uses a Developer ID Application signature and an Apple-accepted, signed disk image with a stapled ticket. Publication status and final source-archive hashes are verified by the release operator; this document records the observed notarization checkpoint.

## Verified distribution evidence

- All **22 acceptance checks passed**, with no skips, in **35.110 seconds** on the Developer ID candidate.
- All four included Mach-O binaries and five architecture slices have Developer ID signatures, secure timestamps and hardened runtime. The app's declared entitlements are preserved; the injected debugging entitlement is removed.
- Apple accepted submission **`08bf7c02-e6fc-4dca-943c-5d35b0985768`**. Its log reports Ready for distribution, status code 0 and no issues.
- The signed DMG's ticket was stapled and validated, and disk-image integrity verification passed.
- Gatekeeper accepted both the exact DMG and the app on the build Mac, identifying them as **Notarized Developer ID**. The source app was not separately stapled or modified after its signing audit.

The final signed/stapled `Robey-Voice-0.1.0-arm64.dmg` SHA-256 is:

```text
9940e59744f41fb2b8e0c24e169018c9eff41293241681a2b4a213ef2717b0ef
```

Download the DMG, named matching source archive, source provenance, build record, distribution status, signing recipe, notarization evidence and `SHA256SUMS.txt` from the same release. Download every file named in the checksum file, then check it from their directory:

```bash
shasum -a 256 -c SHA256SUMS.txt
hdiutil verify Robey-Voice-0.1.0-arm64.dmg
```

The source archive and provenance are refreshed against the committed documentation for this release; their current hashes are in `SHA256SUMS.txt`. GitHub's automatic source exports are separate from the named provenance-backed archive. The [build instructions](../BUILDING.md#developer-id-distribution-and-notarization) document the two required distribution signing options and the explicit signed-DMG submission route; the release's `SIGNING-RECIPE.txt` retains the exact candidate build invocation.

## Requirements and remaining acceptance

Apple silicon and macOS 15 or later are the build targets. Intel, lower-memory variants and actual macOS 15 hardware remain unverified. Apple Speech requires macOS 26 or later. Install the chosen transcription model and supporting assets separately before offline use.

This remains a preview for owner acceptance. Notarization and Gatekeeper assessment do not certify the latest repaired model UI, live microphone dictation, paste/shortcuts, permission denial/recovery, keyboard/VoiceOver/focus behavior, settings transfer/coexistence/replacement/rollback, large FluidAudio interruption/resume, offline first-launch or another Mac. Earlier builds completed actual synthetic Apple Speech and Whisper file transcription with history persistence; those observations remain historical, as recorded in the [validation report](robey-voice-validation.md).

Install through the [normal installation and rollback procedure](robey-voice-installation.md). Microphone and Accessibility permissions still require owner approval through macOS. No permission databases or security policies were changed for notarization.

## Licensing and local use

The app requires no trial, activation, app account, subscription or commercial device quota. Optional cloud services retain their own charges and data handling. GPLv3, original VoiceInk authorship and selected dependency/model notices remain preserved. VoiceInk Refine remains unavailable under its separate model license. The original MIT-licensed Silero VAD detector is included with provenance; newly downloaded transcription/Refine weights, credentials, private fixtures and build caches are excluded from the source package.
