# VoiceInkGG repository review and customization plan

Reviewed November 16, 2026, at commit `b5d1be9` on branch `Customize`. The configured origin is `GrillerGeek/VoiceInkGG`; the application identifies its upstream as Beingpax/VoiceInk, version 2.27. This review covers the source architecture, commercial restrictions, local and remote processing, persistence, dependencies, build configuration, release tooling, and test coverage.

The recommended outcome is a personal GPLv3 fork with unlimited local dictation, its own app identity, optional local text enhancement, and a signed and notarized DMG that can be installed on each compatible Mac. No VoiceInk purchase, activation service, hosted application backend, or paid AI service is necessary for that core workflow. The existing code is a suitable starting point; a rewrite would add substantial work without helping this objective.

This is a source and configuration review with prerequisite checks. Compilation, runtime behavior, signing, notarization, transcription performance, and installation on other Macs remain acceptance work. Dependency license clearance is separate from confirming the application's GPL grant.

## License and ownership

The [README](../README.md) declares GPLv3 and explicitly welcomes forks and modifications for personal use. [CONTRIBUTING.md](../CONTRIBUTING.md) repeats that permission. The checked-in [LICENSE](../LICENSE) contains the GPLv3 heading and preamble, followed by a link to the complete license; it does not contain the complete terms.

My reading is that the GPL grant permits modifying this source to remove trial enforcement, purchase prompts, and activation limits, then building and using the modified app on your own computers. GNU specifically identifies copying software onto multiple computers for yourself as copying that does not convey it to another party. Private modifications, including use within an organization, do not require publishing the fork. See the [GNU licensing FAQ](https://www.gnu.org/licenses/gpl-faq.html#GPLRequireSourcePostedPublic) and its [multiple-computer explanation](https://www.gnu.org/licenses/gpl-faq.html#PropagationNotConveying).

If copies go to people outside that private or organizational use, preserve notices, identify the modifications and date, license the covered derivative under GPLv3, and provide the corresponding source using a compliant distribution method. Providing matching source and build scripts beside each downloadable binary is a practical approach. A public GitHub repository is not a prerequisite for private use. See [GPLv3 sections 4 through 6](https://www.gnu.org/licenses/gpl-3.0.html).

Making this fork yours means controlling its configuration, name, releases, and changes while retaining the original authors' copyrights and license. Use a distinct name and icon to distinguish your build, and retain upstream attribution in an About and Licenses view. Include the full GPL text in the repository and distributed app.

Downloaded models and third-party libraries require their own notices and license review. The README already calls out a separate [FunASR model license](https://github.com/modelscope/FunASR/blob/main/MODEL_LICENSE) for SenseVoice; the app's GPL does not replace those terms. The original [Whisper license is MIT](https://github.com/openai/whisper/blob/main/LICENSE), and the original [Parakeet V3 model card declares CC BY 4.0](https://huggingface.co/nvidia/parakeet-tdt-0.6b-v3). The exact converted artifacts shipped or downloaded by the fork still need a license inventory, including their provenance and attribution. Refine's pinned model license could not be retrieved during this review, so its optional inclusion depends on verifying those terms. Avoid bundling every available model in the first release.

## Architecture and existing capabilities

The repository contains 391 tracked Swift files, a native SwiftUI and AppKit macOS app, and an embedded XPC service for local text enhancement. It targets macOS 15 or later. It has no checked-in application server or account backend that must be deployed for local dictation.

| Area | Existing implementation | Consequence for the fork |
| --- | --- | --- |
| Application composition | [VoiceInk.swift](../VoiceInk/App/VoiceInk.swift) creates persistence, recording, models, enhancement, updates, and navigation | Keep the existing app and service structure |
| Recording and delivery | [TranscriptionPipeline](../VoiceInk/Features/Recording/Workflows/TranscriptionPipeline.swift) handles transcription, vocabulary correction, formatting, replacement, optional enhancement, delivery, and saving | Preserve this pipeline while removing commercial text injection |
| Transcription | [TranscriptionServiceRegistry](../VoiceInk/Features/Recording/Workflows/TranscriptionServiceRegistry.swift) selects Whisper, FluidAudio, TranscribeCpp, Apple Speech, or cloud services | A fully local configuration already exists |
| Text enhancement | VoiceInk Refine through XPC, Ollama, Local CLI, and remote providers | Start with plain dictation; offer a tested local enhancement option |
| Local data | SwiftData stores for transcripts, dictionary, and statistics; preferences in UserDefaults; model and recording files in Application Support | Plan identity changes together with data migration |
| Credentials | [KeychainService](../VoiceInk/Infrastructure/Credentials/KeychainService.swift) and APIKeyManager | Preserve secure API key storage when removing license storage |
| Portability | Settings export includes general settings, prompts, modes, dictionary, and custom model definitions | Reuse for configuring other Macs; it is not a complete history or model backup |
| Platform integration | Global shortcuts, Accessibility, microphone capture, browser automation, optional screen context, clipboard delivery, launch at login | Real macOS permissions and application testing are essential |

Apple Speech is guarded for macOS 26 or later. VoiceInk Refine requires Apple silicon and at least 16 GiB of physical memory according to [VoiceInkRefineService](../VoiceInk/Features/ModelLibrary/State/VoiceInkRefineService.swift). An installation on an older or lower-memory Mac must offer another configuration. Universal architecture settings in the project do not establish that every bundled dependency or inference engine supports Intel.

The code already has useful reliability provisions: recording state management, model prewarming, transcription fallbacks, cleanup controls, Keychain error handling, and an in-memory persistence fallback that displays a warning. These are worth retaining, but they do not substitute for runtime acceptance tests.

## Findings that affect customization

### Existing local builds already allow unlimited use

`make local` adds `LOCAL_BUILD` to a Release build. [LicenseViewModel](../VoiceInk/Features/Licensing/State/LicenseViewModel.swift) initializes that build as licensed, returns licensed state on refresh, and treats its license as verified. Onboarding skips the license step.

The standard build has a seven-day trial, Keychain trial dates, Polar activation and deactivation, and device activation limits. In the inspected delivery path, an expired or absent license prepends a purchase message to delivered transcription text. [TranscriptionDelivery.swift](../VoiceInk/Features/Recording/Workflows/TranscriptionDelivery.swift) is therefore a required removal point, alongside onboarding and purchase UI. This is more than hiding a subscription screen.

No additional commercial word quota was identified in the inspected Swift code. Audio buffering bounds, model chunk sizes, timeouts, and request pacing serve operational purposes and should remain unless a specific defect justifies changing them.

For a durable personal fork, make unrestricted access the normal behavior in Debug, Release, and Archive. Remove the trial and activation subsystem and its UI references. Keeping unlimited use dependent on remembering a special build flag would leave the normal release path capable of restoring the trial behavior.

### Update behavior conflicts with the local build guide

[BUILDING.md](../BUILDING.md) says local builds omit automatic updates. However, [VoiceInk.swift](../VoiceInk/App/VoiceInk.swift) constructs UpdaterViewModel without a local-build guard, and [UpdaterViewModel](../VoiceInk/App/Updates/UpdaterViewModel.swift) starts Sparkle without one. [Info.plist](../VoiceInk/Info.plist) still contains the upstream feed URL, upstream public update key, and enabled automatic checks.

Treat the current local build as potentially checking the upstream feed. It has not been demonstrated that an upstream update would install successfully, but there is no adequate basis for relying on the documentation's claim that updates are absent. Disable updater initialization and remove the upstream feed in the first fork release. Later, use your own feed, signing key, release URLs, and version sequence.

Announcements also use an upstream GitHub Pages URL, fetch shortly after launch and every four hours, and are enabled by default. Remove that fetch and the associated promotional prompts from the personal build. Documentation, support, GitHub star prompts, OpenRouter app attribution, and purchase links also need review so the fork represents its own behavior and destination.

### Signing and release tooling still belong to upstream

The Xcode project, entitlements, [ExportOptions.plist](../release/ExportOptions.plist), [release.sh](../scripts/release.sh), and [notarization setup](../scripts/setup-release-notarization.sh) include the original developer's Team ID, bundle identifiers, iCloud container, Keychain access group, or signing identity. Some release values accept environment overrides, but the expected bundle ID and feed are hardcoded. The archive command uses standard Release without `LOCAL_BUILD`.

Consequently, `make release` is not yet a recipe for an unlimited build signed by you. Create a coherent fork release configuration and parameterize or replace these upstream defaults. Include the embedded XPC service name in the identity change; it is shared through [VoiceInkRefineXPCProtocol.swift](../Shared/VoiceInkRefineXPCProtocol.swift).

The existing release script is worth adapting: it archives, exports, verifies signatures, submits notarization, staples tickets, packages a DMG, verifies the mounted app, and can generate a signed Sparkle feed. Its help explicitly says it does not publish releases or push changes.

### An app rename does not isolate all data

Application Support directories, recording paths, model caches, credential service names, log subsystem names, and the XPC connection name contain hardcoded upstream identifiers. Merely changing the display name and bundle ID would leave shared paths behind. Conversely, changing them all without migration could make existing history, preferences, models, or credentials appear to disappear.

Centralize the fork identity and storage locations. Default to independent fork storage, with an explicit migration or import route if there is existing VoiceInk data. Back up the source data first, copy rather than move it, and verify results before retiring anything. Keep the current settings export secret-free; CustomModelBackup deliberately omits API keys on new exports.

Local builds also change Keychain behavior: they use a separate service and omit the Data Protection Keychain and synchronizable attributes used by standard builds. `LOCAL_BUILD` therefore bundles licensing, CloudKit, and credential behavior together. Separate those concerns when defining the fork's release configuration.

### Local processing must be configured across the whole workflow

Local transcription can be followed by remote enhancement. When enabled, context features can include screen text, clipboard text, or other contextual material in enhancement prompts. Choosing a local speech model alone does not establish a fully local workflow.

Default the fork to local transcription, enhancement off, screen and clipboard context off, and cloud providers available only through deliberate configuration. Keep local CLI and custom shell-command modes optional; a CLI can itself call a paid service. Retain direct dictation when enhancement is unavailable rather than making a remote service mandatory.

History and audio cleanup are disabled by default in [AppDefaults](../VoiceInk/App/Configuration/AppDefaults.swift), so retained data can grow until the user changes those settings. Make retention visible during setup and provide understandable cleanup controls. This is data management, separate from commercial usage limits.

### Builds and tests need a reliable baseline

`make whisper` clones or updates the current whisper.cpp branch and skips rebuilding if an XCFramework is already present. Two computers can therefore build different native dependencies or unknowingly reuse an older binary. Pin its source revision and record the revision used to build the framework. Retain Package.resolved and enforce its revisions; several package requirements follow branches or revisions rather than simple stable release ranges.

The Xcode scheme references a VoiceInkTests target, but no unit-test source files are tracked under that directory. The two tracked UI-test files contain launch, screenshot, and launch-performance scaffolding without meaningful feature assertions. There are no tracked GitHub Actions workflows. Add focused coverage for the behavior changed by this fork and a reproducible build check before relying on a green test command.

Model downloading has mixed maturity. TranscribeCpp artifacts are pinned by revision and expected hash, and Refine uses a pinned snapshot with size and checksum validation. Whisper URLs resolve through `main`. Preserve existing integrity checks and add pinned manifests, recovery from interrupted downloads, and useful offline error messages for the chosen default models.

## Recommended first release

| Decision | Recommendation |
| --- | --- |
| Product | A distinct personal name and icon, with upstream attribution |
| Licensing behavior | Unlimited use in every build configuration, no activation or purchase workflow |
| Default transcription | Compare one Whisper model and Parakeet V3 on your actual Macs and vocabulary; select the default from measured results |
| Enhancement | Plain dictation first; optional Refine on supported Macs or an explicitly configured local Ollama model |
| Remote services | Optional, never necessary for onboarding or dictation |
| Installation | Developer ID signed and notarized DMG; copy the app to Applications |
| Updates | Manual signed releases first; your own Sparkle feed after upgrade testing |
| Cross-Mac settings | Existing export and import, with models installed on each Mac |
| Synchronization | Defer CloudKit until the local build and migration are stable |
| Compatibility | macOS 15 or later; validate Apple silicon first and Intel separately if needed |

Local model inference has no provider usage bill. It still consumes download bandwidth, storage, memory, power, and maintenance effort. Removing VoiceInk licensing does not remove third-party API charges or provider limits when a user chooses a cloud service.

An ordinary Apple Account differs from paid Apple Developer Program membership. The recommended distribution route needs a Developer ID Application certificate and notarization access through that membership. Apple's listed price is $99 USD per membership year; if you already have that membership, this project does not imply a second membership. See [Apple's Developer ID guidance](https://developer.apple.com/developer-id/) and [enrollment terms](https://developer.apple.com/help/account/membership/program-enrollment). No new hosted application service is required for the first release.

The current standard configuration syncs dictionary data through the upstream CloudKit container; Debug and local builds use no dictionary CloudKit database. Reintroducing sync requires your own container, entitlements, provisioning, production schema, and cross-device tests. Existing sync should not be described as syncing all preferences or transcription history.

## Implementation sequence and acceptance

### Phase 1 Establish a reproducible baseline

Inventory the target Macs by OS, processor, and memory. Verify your signing team and Developer ID availability. Pin whisper.cpp, resolve the checked-in Swift package revisions, and build the unmodified baseline into an isolated output directory. Record toolchain and dependency revisions. Exercise recording, transcription, and paste before making functional changes.

**Complete when:** the baseline builds from a clean checkout and a known local model successfully transcribes and pastes on the first Mac. Hardware-specific exclusions are documented.

### Phase 2 Remove commercial restrictions

Remove license and trial state, Polar calls, trial dates, activation limits, purchase and license onboarding, dashboard trial messaging, sidebar license management, and the transcript purchase prefix. Update diagnostics and localization references. Keep provider API keys and general Keychain support. Make the default build unrestricted rather than extending trial dates or simulating a purchased license.

**Complete when:** fresh and previously expired installations both onboard and deliver clean text without a license key. Advancing the injected test clock beyond seven days, missing old license credentials, and unavailable licensing endpoints do not change access. Debug, Release, and the archived app all behave the same way.

### Phase 3 Establish the fork identity and local defaults

Select the final app name and identifiers; update the app, XPC service, signing configuration, storage, Keychain service, diagnostics, support destinations, and launch integration together. Preserve copyrights, add modification notices, include the complete GPL, and assemble dependency and chosen-model notices. Disable upstream updates, announcements, and promotional flows. Configure local processing and optional context features explicitly. Add a backed-up migration route if existing data needs importing.

**Complete when:** the fork can coexist with upstream using independent storage, no upstream commercial endpoints are contacted, and a configured local workflow works with network access unavailable after model installation. Missing models produce a clear installation action without requiring an app account.

### Phase 4 Produce the signed installation package

Adapt the archive and export pipeline to your team and the fork's entitlements. Verify all nested frameworks and the XPC service use the intended identity and hardened runtime. Produce the DMG, notarize and staple it, and retain hashes, source revision, dependency manifest, and a matching source archive. Confirm actual binary architectures instead of assuming a universal build.

**Complete when:** signature, notarization-ticket, and Gatekeeper checks pass, and the downloaded DMG launches on a second Mac or fresh test account without development tools. macOS permission grants remain a normal per-machine setup step.

### Phase 5 Validate daily use and deploy to the other Macs

Verify microphone and Accessibility permission denial and recovery, shortcuts, push to talk, text insertion into a native editor, browser, and terminal, clipboard restoration, cancellation, file transcription, history persistence, retention, model-download recovery, sleep and wake, and input-device changes. Compare model quality and latency using your names and technical vocabulary. Verify local enhancement where hardware permits it, plus usable plain dictation when enhancement is off. Export and import settings onto another Mac.

**Complete when:** each target hardware and OS combination passes the chosen core workflow, a replacement installation preserves fork data, and rollback to the previous package is understood and tested against its data format. No claim of support for all Macs precedes those checks.

### Phase 6 Add update and sync conveniences

After the first dependable release, optionally add your Sparkle feed and EdDSA key, release hosting, increasing build numbers, and a tested upgrade from the previous release. Validate that upstream updates cannot be selected. Add CloudKit dictionary sync only if it is useful enough to justify its separate configuration and acceptance work.

**Complete when:** a previously installed fork receives and verifies a fork update while preserving data and retaining usable macOS permissions. If sync is added, dictionary changes converge on two Macs using your own container.

## Current verification and remaining decisions

`make check` passed. The selected tools report Xcode 27.1 and Apple Swift 6.4 on arm64, satisfying the build guide's stated Swift 6.2 minimum. Both release shell scripts passed `bash -n`. The expected whisper.xcframework was absent at its documented default path, so no application build or runtime test was completed. Signing identities and account membership were not inspected, and no model or dependency downloads, app installations, permission changes, or Apple submissions were performed.

The implementation needs the final app name and bundle namespace, the list of target Macs, and whether existing VoiceInk data should be imported. Cloud providers, automatic updates, and CloudKit can remain optional decisions without delaying the first dependable local release.

The first deliverable should be one unrestricted, independently identified, signed app that proves local dictation on two Macs. That provides a firm basis for broader installation and later conveniences.
