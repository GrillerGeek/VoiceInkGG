# Robey Voice installation and rollback

This runbook covers the 0.1.0 Apple silicon build with a macOS 15 deployment target. Intel and installation on another Mac remain separate validation gates. Use the [validation record](robey-voice-validation.md) to establish which artifact and native checks have actually completed.

## Identify the Package

Download the assets from the **[0.1.0 notarized preview](https://github.com/GrillerGeek/VoiceInkGG/releases/tag/v0.1.0-notarized)** into one directory. Use `Robey-Voice-0.1.0-arm64.dmg`, `Robey-Voice-0.1.0-source.tar.gz`, `source-provenance.json`, `build-record.json`, `DISTRIBUTION-STATUS.txt`, `SHA256SUMS.txt`, and the accompanying signing/notarization evidence from that same release. Download every file named in `SHA256SUMS.txt` before checking it. The named source archive has the package's per-file provenance; GitHub's automatic source ZIP/tarball is a separate repository export.

The notarized package is Developer ID signed. Apple accepted submission `08bf7c02-e6fc-4dca-943c-5d35b0985768`; the signed disk image's ticket was stapled and validated, disk-image integrity passed, and Gatekeeper accepted both the disk image and app as `Notarized Developer ID` on the build Mac. The app itself was not separately stapled. Offline first-launch and installation on another Mac have not been tested. See the [notarized release notes](robey-voice-release-0.1.0-notarized.md).

Check the downloaded files from their directory:

```bash
shasum -a 256 -c SHA256SUMS.txt
hdiutil verify Robey-Voice-0.1.0-arm64.dmg
```

Read `DISTRIBUTION-STATUS.txt` and retain the notarization evidence. The local notarized package is in `.review-build/notarized-release-v0.1.0/`. The [original preview](https://github.com/GrillerGeek/VoiceInkGG/releases/tag/v0.1.0) and `.review-build/review-package/` are preserved historical Apple Development-signed, non-notarized artifacts. Their old hashes and signing limits do not describe the notarized disk image.

Build instructions, including the required distribution signing options, are in [BUILDING.md](../BUILDING.md). Local Apple Development or ad-hoc builds are not notarized and can be rejected on another Mac. Do not disable Gatekeeper, remove quarantine as an installation recipe, or modify security databases to make a build appear accepted.

## Install and Set Up

1. Quit any running Robey Voice build. Keep the previous app and a backup of its data if this is a replacement.
2. Mount the DMG and drag `Robey Voice.app` into Applications. For a local build without a DMG, copy the completed app bundle from the documented DerivedData path.
3. Open the app. Use macOS's supported prompts and Privacy & Security settings to review any blocked launch or requested permission. A rejected development build may need a different signing/distribution route.
4. Complete onboarding. Microphone enables recording; Accessibility enables text delivery. Current onboarding requires both even when the intended workflow uses imported audio. The owner must grant permissions through normal system flows. Unattended automation cannot count these as granted or tested.
5. Choose a local transcription setup and download its model while online. Wait for the model to be installed and selectable. Whisper imports, downloads, and discovery validate the supported GGML container before marking it ready; a failed load withdraws readiness. Invalid existing files are preserved for inspection and can be replaced through retry or reimport. FluidAudio setup that is interrupted or fails remains not ready across restart and offers Resume Download; only successful native setup clears that state. Verify readiness before disconnecting. These recovery paths have automated/source checks; the latest native setup UI remains to be exercised.
6. Keep AI enhancement and sensitive context features off for plain local dictation. Skip optional API setup. Configure cloud providers, Ollama, Local CLI, custom commands, browser automation, or screen context only when you intend to use them.
7. Review History retention and audio cleanup settings. Retention is not a commercial usage limit; saved recordings and transcripts can consume storage.

Transcription and Refine model weights are not bundled. The app retains the existing MIT-licensed Silero VAD detector, which detects voice activity and does not replace a speech transcription model. Offline use requires the chosen transcription model and any provider-specific supporting assets to be installed first. A local speech model followed by a remote enhancement provider still sends data to that provider. Whisper and Parakeet downloads can resolve mutable model revisions; see the [model provenance limits](../VoiceInk/Resources/Legal/THIRD_PARTY_NOTICES.md). Apple Speech requires macOS 26 or later. VoiceInk Refine is unavailable because of its separate model license; plain dictation or a deliberately configured permitted provider is the recovery path for an imported Refine selection.

Denied permission is recovered through System Settings > Privacy & Security for the installed Robey Voice app. Reopen the app if macOS requests it. Screen capture and Automation are optional feature permissions. No permission grants are transferred between Macs or guaranteed to survive a rebuild.

## Data Locations

| Build | Bundle ID, defaults domain, and Keychain service | Application Support |
| --- | --- | --- |
| Release | `com.jasonrobey.RobeyVoice` | `~/Library/Application Support/com.jasonrobey.RobeyVoice/` |
| Debug | `com.jasonrobey.RobeyVoice.dev` | `~/Library/Application Support/com.jasonrobey.RobeyVoice.dev/` |

Credentials use the device-local login Keychain without synchronization. Debug and Release settings, models, and credentials are separate. Robey Voice does not automatically read, move, delete, or convert upstream VoiceInk databases, preferences, model caches, or Keychain items. There is no CloudKit dictionary synchronization in this release.

## Transfer Settings

1. In the source app's Settings, choose Export Settings and save the versioned JSON backup.
2. Keep the original data and app intact. Review the backup before sharing it: prompts, vocabulary, endpoints, mode text, and command definitions can contain personal or manually embedded sensitive information.
3. In destination Robey Voice Settings, choose Import Settings and select all or specific categories: General Settings, Custom Prompts, Modes, Dictionary, and Custom Model Definitions.
4. Review the imported settings and restart if prompted. Download local models separately and re-enter any required API keys on the destination Mac.

New exports omit provider API secrets, trial state, and machine permission state. They do not include transcription history, recordings, or model weights. The existing decoder can accept API keys embedded in older custom-model backup files, so treat legacy backups as sensitive. Import is an explicit user-selected operation, not automatic upstream migration. Existing saved/imported choices are honored; fresh defaults do not override them. Confirm that imported modes do not enable an unintended provider or command.

## Replace and Roll Back

Before replacing a production build, export settings, quit the app, and back up the complete production Application Support directory plus the previous app bundle using your normal backup tool. Keep the source/package provenance and checksums with that version. Settings export alone is not a history backup, and a filesystem copy does not transfer device-local Keychain credentials.

Replace only `Robey Voice.app` in Applications and reopen it. Production builds retain the same data identity; do not delete Application Support to update. Keep the upstream VoiceInk app and its data untouched. Verify settings, a synthetic transcription, history after relaunch, and text delivery before retiring the previous app.

If replacement fails, quit it and restore the previous app bundle. Older app versions may not understand a newer database format. Restore the matching pre-update data backup while the app is stopped if needed, preserving a separate copy of any newer data for recovery. Do not merge database files by hand. Permission reapproval may be required. Replacement, rollback, and second-Mac preservation are pending until actually exercised against a packaged build.
