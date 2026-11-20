# Robey Voice implementation plan

## Context and authority

Jason approved the repository review and authorized autonomous implementation, specialist delegation, branding decisions, and preparation of a working solution for later review on November 16, 2026. The source review is [here](../../2026-11-16-repository-review-and-customization-plan.md). This plan is the execution checklist and standalone non-IDD specification for that approved scope. There is no existing IDD Product or lifecycle to advance and no claim of separate human Spec acceptance. The explicit request to implement autonomously supplies authority for routine implementation and branding decisions.

Baseline: branch `Customize`, commit `b5d1be9a7c7377dd059f37bb3e0f791b802d4001`. The pre-existing untracked review document is preserved. Execution started at 2026-11-16T13:35:04Z.

Mode: feature implementation with independent acceptance tests, sequential implementation, specialist review, build verification, and native macOS walkthrough. The Guildhall skill supplies role separation and evidence gates. User instructions to continue autonomously take precedence over inferred approval steps and arbitrary retry stops; failures will be investigated and recorded without declaring success. No IDD statuses, external publication, or permission bypasses are implied.

## Assumptions and decisions made for Jason

- Working name: **Robey Voice**. Bundle namespace: `com.jasonrobey.RobeyVoice`; development build and embedded XPC service have distinct suffixes.
- Branding: a clean teal and dark-ink identity with an original waveform mark; native macOS controls, light and dark appearance, and accessible labels. Branding remains subject to Jason's later review.
- Private personal use on Jason's compatible Macs is the initial audience. Original copyrights and GPLv3 are preserved.
- No app subscription, license key, activation server, commercial device count, or word quota will be required in any build configuration.
- Local speech recognition is the default. Remote transcription, remote enhancement, optional screen or clipboard context, and custom commands require deliberate configuration.
- The first dependable release uses manual updates, no upstream feed, no upstream announcements, and no CloudKit dependency. Own-feed updates and cross-device dictionary sync are later conveniences.
- License-driven amendment: exclude the separately licensed VoiceInk Refine model from download/execution in this fork. Its exact pinned license restricts use to VoiceInk and prohibits use in other software/open-source projects and redistribution without permission. Local dictation and optional Ollama remain supported. This is the documented incompatibility exception under B6; no right to the model is inferred from the application's GPL.
- Fork data and credentials are isolated from upstream. Existing data is preserved; settings import is supported. No automatic move, deletion, or conversion of an upstream database is authorized.
- Apple silicon is the first verified platform. Intel support is claimed only if the actual dependency and binary checks justify it. macOS 15 remains the intended minimum, with provider-specific requirements visible.
- Dependency and model downloads needed for building and synthetic validation are authorized. Do not use existing private recordings, transcripts, API keys, or accounts as test fixtures.
- Existing signing identities may be inspected and used for this authorized build. Never export a private key or put credentials in the repository. Creating a paid account, purchasing a service, or publishing a public release is outside this scope.
- App launches and task-owned file transcription are authorized. Prefer generated synthetic audio; an independently licensed public reference sample may be used if local speech synthesis is unavailable, with exact provenance and no implication that it is synthetic. Do not record ambient microphone audio or send user data to a remote provider. macOS permissions must use supported system flows; do not modify TCC databases or bypass Gatekeeper.
- Source changes may be committed locally with explicit pathspecs after validation if useful for a durable deliverable. Do not push or open a PR without separate authorization; prepare a local PR draft instead.

## Standalone specification

### Purpose

Deliver a maintainable, independently branded macOS dictation app that Jason can build and install on compatible Macs, with unlimited local use, no VoiceInk licensing dependency, and a reviewable installation artifact.

### Expectations

E1. Fresh, previously expired, and long-running installations can complete onboarding and transcribe without a license, trial, purchase, activation, account, or commercial device limit. This holds in Debug, Release, and Archive.

E2. Delivered text is the requested transcription or enhancement output without commercial prefixes or purchase messages. App navigation, diagnostics, and onboarding contain no license management or trial states.

E3. The app never initializes an upstream update or announcement service. It has no upstream update feed or public update key configured. Manual update information truthfully explains the installation procedure.

E4. The app, helper, credentials, storage, logs, signing settings, installer, and user-visible identity consistently identify Robey Voice. Upstream authorship, GPLv3, dependency notices, and model provenance remain available.

E5. A fresh configuration permits local dictation without cloud credentials. Enhancement and sensitive context features default off. Missing local models have an actionable install/retry state, and provider-specific OS or hardware requirements are visible.

E6. Upstream application data and credentials are preserved and not read automatically. Fork settings can be exported and imported without exporting API secrets. Existing explicit user-selected imports remain supported.

The supported settings transfer keeps the existing versioned JSON schema and allowlisted categories: general settings, prompts, modes, dictionary, and custom model definitions. New exports exclude API secrets, trial state, and machine permission state. This does not require a database or model-weight export, or changing the existing schema unnecessarily.

E7. Dependency source revisions and package resolution are reproducible. A documented build uses workspace-owned dependency/output paths and does not silently update a previously built native dependency.

E8. A real Release application builds and its executable and embedded components have verified architectures and signatures. Prefer an available stable Apple signing identity; create a notarized DMG if Developer ID and notarization credentials are usable. Missing credentials must be reported precisely, with the strongest working local artifact still produced.

E9. Native app launch, onboarding, model setup, synthetic file transcription, persistence, and clean text delivery are verified as far as the available macOS session permits. Unavailable permission, microphone, second-device, or signing checks are explicitly pending, never reported as passed.

E10. The repository includes focused automated regression checks for the fork's acceptance behavior, truthful build/install instructions, a validation record, and a review checklist. Checks must catch real commercial enforcement or upstream-service regressions rather than merely mirror changed strings.

E11. Failures in optional enhancement or network services do not make a configured plain local dictation workflow require an account or purchase. Operational bounds such as chunk sizes, timeouts, and buffer limits remain intact.

E12. The final artifact and documentation clearly distinguish local signing from notarized distribution, identify supported hardware, and include a matching source revision or source archive and checksums suitable for review.

### Edge cases

EC1. An old installation has an expired trial date or saved license state: the fork's access remains unlimited and no old credential is needed.

EC2. More than seven days pass or the system clock changes: no trial behavior appears.

EC3. The network is unavailable after local model installation: local transcription remains usable without a commercial service.

EC4. A model download is interrupted, missing, or invalid: setup offers a clear recovery path and does not claim the model is ready.

EC5. Microphone or Accessibility permission is denied: the app explains recovery without a crash or permission bypass.

EC6. A Mac is Intel, has less than 16 GB RAM, or runs macOS 15: unsupported optional providers are identified, and a supported local path is offered where the compiled dependencies permit it.

EC7. Upstream VoiceInk and Robey Voice coexist: credentials and data remain isolated, and neither app's data is moved or deleted.

EC8. A user selects a cloud provider or shell command explicitly: the feature remains available with honest configuration requirements; its external costs are not represented as removed by the fork.

EC9. No usable Developer ID or notarization profile exists: produce and validate the locally runnable artifact, record the exact missing prerequisite, and do not describe it as notarized.

EC10. Replacing a Robey Voice build preserves its data. macOS may require normal permission approval; test and report actual behavior rather than promising perpetual grants.

### Boundaries

B1. Preserve original copyright attribution, the GPLv3 grant, existing user data, pre-existing edits, and third-party license notices.

B2. Do not publish, push, purchase, enroll in paid services, export signing private keys, or expose credentials.

B3. Do not modify upstream app data, TCC databases, system security policy, or real-device state beyond launching the authorized app and supported permission flows.

B4. Use task-owned synthetic audio and data, or an explicitly identified legally usable public reference sample, for validation. Do not capture ambient microphone audio or transmit private data to cloud providers.

B5. Keep runtime logs, downloaded dependencies, newly downloaded model weights, build products, signing credentials, and private test artifacts out of tracked source. Preserve the pre-existing bundled Silero VAD model only with its verified checksum, provenance and MIT notice.

B6. Retain operational safeguards and optional provider capabilities unless a specific incompatibility is documented. Do not rewrite the recording pipeline or add a required backend.

B7. Writers may edit only their explicitly assigned paths. Tests accepted before implementation are read-only to implementers. Serialize overlapping writes and preserve other workers' changes.

B8. Do not infer human branding acceptance, second-Mac acceptance, notarization, or successful dictation from source inspection or synthetic UI fixtures.

B9. Every completed checklist item needs actual source, command, artifact, or observed UI evidence; report missing or failed checks explicitly.

### Deliverables and validation

D1. Updated application and release/build configuration implementing E1–E8 and E11.

D2. Independent focused regression checks with recorded baseline failure and passing final results; real Release build and signature/architecture evidence.

D3. Original branding assets and a preview, complete GPLv3 and required selected-dependency/model notices.

D4. Reviewable app/package under ignored output storage; notarized DMG when credentials allow; matching source provenance and checksums.

D5. Updated README and BUILDING, installation and rollback runbook, validation report, and local draft PR description.

D6. This maintained checklist, assumptions, specialist findings, native walkthrough evidence, and explicit remaining human or external prerequisites.

### Public identity contract for independent tests

`Shared/AppIdentity.swift` is a Foundation-only source usable by the app and helper and compilable by an isolated Swift acceptance harness. It declares `enum AppIdentity` with these read-only static String properties:

- `displayName`: `Robey Voice`.
- `productionBundleIdentifier`: `com.jasonrobey.RobeyVoice`.
- `developmentBundleIdentifier`: `com.jasonrobey.RobeyVoice.dev`.
- `bundleIdentifier`: development identifier when compiled with `DEBUG`, production identifier otherwise.
- `applicationSupportDirectoryName`: the current `bundleIdentifier`.
- `keychainServiceName`: the current `bundleIdentifier`.
- `logSubsystem`: the current `bundleIdentifier` lowercased.
- `refineXPCServiceName`: `com.jasonrobey.RobeyVoice.RefineXPC`.

Development builds use independent development data and credentials. Replacing a production release retains the stable production identity. The internal Swift module may remain named VoiceInk. This API establishes identity only; it contains no licensing state or feature-access flags. Additional compatible helpers may be added when needed.

First-release entitlement contract: remove all configured CloudKit containers/services and APNs entitlements, since this release uses local persistence and manual updates. Preserve needed non-cloud capabilities. A future own-container sync feature is outside this release.

Accessibility validation contract: accent-filled body-size button labels must meet WCAG AA contrast of at least 4.5:1 against the configured light and dark AccentColor asset. The existing `AppTheme.Text.onAccent` static SwiftUI Color in `VoiceInk/DesignSystem/Theme/AppTheme.swift` is the common foreground API and must resolve appropriately in Aqua and Dark Aqua. An isolated native Swift harness may compile that theme source as an opaque test subject, resolve its foreground through NSColor under each appearance, and compare it with the catalog colors. UI callers using literal white on the custom mint fill must switch to the common adaptive foreground. The About title and section titles must expose native accessibility heading semantics.

Invalid-model acceptance follow-up: `Shared/WhisperModelValidator.swift` exposes `enum WhisperModelValidator` with `static func validate(at url: URL) throws`. It may use Foundation and the pinned native whisper module. Independent behavioral checks must accept the verified Tiny English model and reject empty, text/HTML, header-only, truncated (including near EOF), nonsensical/overflowing-header and unknown-format files. Supported vocabulary header counts are 51864, 51865 and 51866, matching the pinned native library's language-token range. Cumulative vocabulary token bytes are limited to 8 MiB, with cancellation checks during metadata loops. Discovery, import and download must validate before advertising readiness; a native load failure must invalidate readiness and provide recovery. Validation must be bounded and avoid initializing GPU inference or reading all tensor payloads merely to scan installed models. This makes EC4's existing requirement concrete; it does not broaden model execution or download authority.

Setup-readiness acceptance follow-up: Foundation-only `Shared/ModelSetupReadinessStore.swift` exposes `final class ModelSetupReadinessStore`, `init(defaults: UserDefaults, key: String)`, `requiresRetry(for modelName: String) -> Bool`, `beginSetup(for modelName: String)`, and `completeSetup(for modelName: String)`. A begun FluidAudio setup persists its retry requirement through interruption, failure and process restart; only verified successful setup clears that model's marker. Independent tests use unique synthetic defaults domains and separate processes. Existing model files and unrelated preferences are preserved.

## Host capabilities and dispatch

Host: Codex with native `collaboration.spawn_agent`, fresh contexts through `fork_turns: none`, four concurrent slots including the orchestrator. Model overrides are supported, but no exact model was selected by the user; specialists inherit the configured capable model rather than translating Claude roster aliases. Trusted applied model metadata is not exposed, so observed identity is **unknown**.

Filesystem and network permissions remain enforced. Role-specific read restrictions are instructions, not isolated filesystems. Terminal checks, native app/browser CUA, and image inspection are available. No Playwright setup exists for this native Swift app; native CUA and application tests are the relevant walkthrough mechanisms. A second physical Mac is not exposed. Signing access and Apple membership are to be discovered.

The canonical review surface is this repository and the existing review document. User authorization and preferences came from the current conversation. No external Page or publication is required for this repository execution plan; no hosted review is claimed.

Dispatch sequence:

1. Independent architecture consultation on identity, unrestricted use, and build/signing configuration; parallel read-only environment and dependency preparation assessment.
2. Fresh-context test author receives only the specification and test conventions. Observe meaningful RED and preserve tests.
3. Implementer owns app and build changes after RED. Prepare dependency builds and artifact validation in disjoint generated directories as needed. No overlapping source writers.
4. Separate docs and branding work receive explicit disjoint paths; implementation continues to the full acceptance target.
5. Independent security, reliability, observability, performance, operations, migration/isolation, accessibility, documentation, and native UI review; consolidate findings and resolve material issues.
6. Closing architecture/technical review against all Expectations, edge cases, Boundaries, and Deliverables.
7. Produce local PR draft, runbook, artifact links, and final evidence with pending human checks clearly marked.

Guildhall role bodies are read from the installed bundle by each specialist in bounded outputs. Delivery completeness not visible in trusted host output is recorded as unknown rather than inferred from a worker assertion. No implementation or solution-proposal context goes to the test author.

## Execution checklist

- [x] Preserve baseline and approved review; record scope, assumptions, boundaries, and capabilities.
- [x] Obtain architecture consultation and settle execution design.
- [x] Inspect build tools, native dependency requirements, available identities, and notarization prerequisites.
- [x] Author independent acceptance checks and observe meaningful baseline failures.
- [x] Remove trial, activation, purchase UI, and transcription purchase text in all configurations.
- [x] Remove upstream update and announcement initialization and promotional flows.
- [x] Apply fork identity consistently, isolate storage, retain settings portability and attribution.
- [x] Install original icon, accent theme, About and Licenses information.
- [x] Establish local defaults and actionable model setup; preserve permitted optional providers.
- [x] Pin dependencies and provide reproducible build and package commands.
- [x] Build Release, run acceptance checks, verify signatures and actual architectures.
- [x] Launch app and inspect onboarding/model setup with native UI tools; security permission approval remains human acceptance.
- [x] Transcribe synthetic audio with a real local model and verify clean output and persistence.
- [x] Package installable app/DMG, notarize if credentials permit, record checksums and source provenance.
- [x] Complete independent specialist reviews and resolve material findings.
- [x] Update user/build/license documentation, runbook, validation report, and local PR draft.
- [x] Complete final technical review and produce review package.

## Selected reviewers

Security, reliability, observability, performance, operations, migration/isolation, accessibility, documentation, native UI, and closing technical review apply because the change touches credentials, optional network services, model execution, storage identity, app installation, and user-visible setup. Plugin validation is skipped because no plugin package is changed. Browser Playwright tests are inapplicable to the native app; native UI verification is required and any unavailable interaction stays pending.

## Out of scope and later work

Automatic update hosting, public releases, App Store distribution, CloudKit provisioning, automatic database migration, real microphone recordings without Jason present, and installing on unavailable remote Macs are deferred. A lack of access to any of these does not prevent completing independent local implementation and packaging.

## Verification evidence and progress

2026-11-16T13:35:04Z: worktree initially contains only the pre-existing untracked review document. No application source edits precede this plan. Earlier review verified `make check` and shell syntax, but did not compile the app. Runtime and distribution claims remain unverified.

Progress record: sibling `2026-11-16-robey-voice/progress.json`, maintained through the installed Guildhall progress helper. The checklist and this evidence section remain the detailed canonical account.

Architecture consultation: unrestricted access will be unconditional, with independent fork identity, storage, signing, and disabled CloudKit. Globally forcing `LOCAL_BUILD` was rejected because it bundles unrelated credential and cloud policies while retaining commercial UI. Existing release skip flags still read upstream identity/feed values and need a real fork release path. The architecture consultant found the Spec checkable for independent tests; the exact public identity API and development isolation policy above settle its remaining test-contract ambiguity.

Initial independent RED (before source edits): test author reported 8 tests, 5 assertion failures, 1 pass, 2 artifact skips, 0 errors. Four failures identify missing promised `Shared/AppIdentity.swift`; one identifies configured upstream feed/public key. Root inspected the two test sources. Before acceptance freeze, root authorized a test-only revision to remove a harmless docstring escape warning and add opaque commercial-symbol and CloudKit entitlement audits. Final accepted RED and test hashes follow after that revision.

Accepted independent RED: root ran `python3 -B -m unittest discover -s Tests/PersonalForkAcceptance` and observed exit 1, 11 tests, 7 assertion failures, 2 passes, 2 artifact skips, 0 errors. Failures are four missing promised identity API cases, retained commercial type dependencies, upstream update keys, and CloudKit/APNs entitlements. The scanner fixture and exact package-revision audit pass. The test author also compiled the harness against a synthetic conforming identity in Debug and optimized Release to exclude fixture/tooling errors.

Frozen tests: `Tests/PersonalForkAcceptance/identity_main.swift` SHA256 `8d7b8a5f5b6f79a4b2964b2d7b77e31a3b9cccb758fdb237d6cdd0e4337b277d`; `Tests/PersonalForkAcceptance/test_personal_fork.py` SHA256 `60dd0fadd7a743147ca8d4e0bbf46510ce1cc651be548e03c1661a38aad3af50`. Implementers may read but not edit them. Numeric goal: seven RED tests become passing, no regression among two passing checks, and both artifact gates run against the real packaged app.

Writer ownership after RED:

- Application specialist: app Swift source, Shared identity/protocol, XPC Swift, app Info.plist/entitlements/localization; excludes assets/legal resources/tests/build tooling/docs.
- Build specialist: Makefile, LocalBuild.xcconfig, project.pbxproj, scripts, release configuration, .gitignore, generated dependency/build/package outputs; excludes app source/tests/docs/assets/legal.
- Branding and legal specialist: Assets.xcassets branding, `branding/` vector sources/generator, `VoiceInk/Resources/Legal/`, complete root LICENSE and optional root notices; excludes app Swift/build/tests/docs.
- Orchestrator: this plan and helper-managed progress only. Checks and native walkthrough generate evidence without editing application source. Documentation and final review records will receive explicitly scoped writers.

First integrated GREEN: root independently ran the frozen suite and observed exit 0, 11 tests, 9 passes, 2 artifact skips. Both test file hashes match the accepted RED freeze. This proves the isolated identity contract and source/config regressions only; a real app build and native transcription remain required.

Build environment findings: Xcode initially failed to load IDESimulatorFoundation because installed developer frameworks were out of sync. The build specialist's supported `xcodebuild -runFirstLaunch` repair reported Install Succeeded. Escalated identity discovery found one Apple Development identity and no Developer ID identity. Neither the RobeyVoice-Notarization nor existing upstream-named notarization profile has stored credentials. Pursue an Apple Development-signed local artifact and label distribution limitations precisely; notarization is unavailable with the currently discovered credentials. Native dependency candidate: whisper.cpp v1.8.3, exact revision `2eeeba56e9edd762b4b38467bab96c2517163158`, cloned into ignored workspace-owned storage.

Model licensing finding: branding/legal specialist retrieved `beingpax/VoiceInk-Refine-V1` at pinned revision `ad665418d3850e379e29236e66be3ddc0ac0bf04`. LICENSE.md restricts use with the VoiceInk application and forbids other software/open-source use and redistribution without permission. Decision: disable/hide its installation and execution, retain honest provenance and imported-selection recovery, and optionally exclude its inactive XPC/MLX dependency build after app/build coordination. This supersedes the initial assumption that Refine could be offered as an optional local model.

Application checkpoint: implementer reports 157 owned paths (19 deletions), full Swift frontend parse, isolated identity/Keychain/manual-updater/About native typecheck, clean whitespace check, and unchanged frozen tests. Source ownership released for read-only review, with integrated compiler corrections reserved. Additional discovered isolation surfaces fixed: FluidAudio and VAD global caches, custom sounds, localized InfoPlist display names, and logger/export subsystem names. Preparation of onboarding no longer clears saved/imported modes. Sensitive fresh defaults now leave automatic correction observation and selected/screen/clipboard context off, while explicit saved/imported choices remain honored.

Native validation boundary: existing onboarding requires microphone and Accessibility before completion, even for file transcription. No security permission will be granted unattended. A supported fork-only synthetic `hasCompletedOnboardingV2` test seed may be used to exercise real file-import UI and actual transcription; that is seeded navigation, not completed permission onboarding. Permission recovery and real microphone/second-device acceptance remain separately pending.

Brand QA: root viewed `.review-build/branding/brand-review.png` and confirmed waveform legibility from 16 to 256 px in light and dark contexts. This is visual implementation QA, not Jason's branding acceptance. Root directly read the pinned Refine model license and confirmed the restriction, rather than relying only on the worker report.

Independent source security review: clean across 157 files and 7,606 delta lines; no introduced vulnerability finding. Independent reliability review: zero high/medium/low/info findings, including exact pinned FluidAudio API validation. Both exclude unfinished build/package/legal artifacts and leave runtime evidence pending.

Accessibility review identified an actionable medium contrast issue: the new dark-appearance mint fill is paired with explicit white small text in four model/file-transcription controls. Low-severity About heading semantics are also missing. The independent test author will add a separate contrast regression without changing the frozen original suite; the app writer owns corrections, followed by review refresh.

Contrast follow-up evidence: the first test-author follow-up stopped before any write after a bounded plan extractor exposed later review prose. Original test independence and frozen files remain intact. A new fresh-context author received only a quoted public contrast contract and produced two new tests without reading implementation or review prose. Root independently observed meaningful RED: 7 tests, 6 passes, 1 Dark Aqua failure, exit 1; native SwiftUI-to-NSColor bridge calibration and math fixtures passed. Original measured dark ratio was 1.495453:1; light was 5.932228:1.

Frozen follow-up files: `test_brand_contrast.py` SHA256 `8ec3176ba2a9dc667aaca61b6a5f8411fe3e6d18f68a9c8e5827668e17ea4350`; `contrast_main.swift` SHA256 `beb9b8fb6da693e4bd204bf4a7fe13b4126d821747d88647b24a9b012675dd68`. App correction uses white for light teal and ink for dark mint, updates the five actual accent-filled caller controls, adds About heading traits and menu-bar accessible name. Root independently ran the combined suite: exit 0, 18 tests, 16 passes, 2 real-artifact skips, 17.492 seconds. Measured ratios: Aqua 5.932228:1, Dark Aqua 9.988459:1. All four frozen file hashes are unchanged.

Accessibility refresh resolves all prior source findings. One info item remains: verify semantic destructive/system-red foreground contrast independently of the custom accent, plus actual pressed/focus/VoiceOver states. These are not established by accent measurements. Performance source review reports no findings and bounded model state/static identity overhead. Observability reports one low item: an imported Refine mode launched via shortcut can fall back to plain text without a per-operation explanation, although dashboard/editor warn; owner is application maintenance, follow-up bounded status/log without transcript contents. No unmet unlimited-access requirement is inferred from that optional-provider degradation.

Native engine: pinned whisper.cpp framework built successfully for arm64/macOS 15 with Metal and CoreML. Actual framework and CLI are in ignored `.local-dependencies/whisper.cpp/`; build output in `.review-build/whisper-build.log`. One original SPM graph resolution completed; the builder is resolving the reduced graph after excluding inactive restricted-model dependencies.

Build-script review follow-ups assigned to builder: remove obsolete LOCAL_BUILD flag and canonicalize package output paths before enforcing ignored output boundaries. Main project naming/version is Robey Voice 0.1.0 with internal VoiceInk scheme/module; no active Refine XPC target is packaged. Branding/legal completed full GPL/model notices and supplied an offline dependency-license collector; final package checkout inventory remains to be refreshed by the builder.

Fixture assumption amendment: root independently inspected the first generated WAV with `afinfo` and found zero duration, bytes and packets. It is invalid evidence and must not be called a transcription test. Prefer regenerating TTS through supported execution outside the restrictive sandbox. To avoid requiring private or ambient recordings if local TTS is unavailable, B4 now also permits a task-owned copy of an explicitly identified legally usable public reference sample, with exact provenance. This does not expand access to private recordings or cloud transmission and follows the user's delegated implementation discretion.

Actual engine validation: supported execution outside the restrictive sandbox generated a valid Samantha TTS fixture, 112,916 mono samples at 16 kHz, 7.05725 seconds, SHA256 `e764d9389656f944dc3c827d3e4ae8c6e309dc4958cb484866983007b5893507`. No public reference or microphone recording was needed. Pinned Tiny English weights from GGML conversion revision `5359861c739e955e79d9a303bcbc70fb988958b1` matched LFS SHA256 `921e4cf8686fdd993dcd081a5da5b6c365bfde1162e72b08d75ac75289920b1f`. Whisper CLI transcribed the exact expected word sequence with punctuation/linebreak differences only; evidence `.review-build/fixtures/validation.json`, `whisper-cli.log`, `whisper-result.txt`. The sandbox Metal process crashed and sandbox signature checks could not see trust state; the unchanged binaries passed outside that environment, so sandbox results are recorded as environmental limits rather than product validation.

Actual app build and artifact validation: Xcode Release succeeded with Apple Development signing, own identity/version and arm64 main executable. All 18 frozen acceptance tests passed with no skips outside the sandbox; saved `.review-build/acceptance-artifact.log`. Packaged components: app arm64, whisper arm64, MediaRemoteAdapter arm64, CTranscribe arm64+x86_64; inactive Refine XPC absent. Final Legal hierarchy exists under app Resources/Legal. Builder source/app binding and exact clean dependency checks are in place; final VAD/legal/tooling updates require a final incremental rebuild and refreshed package.

Native CUA evidence on the first signed app: launched into branded permissions screen; Microphone Allow and locked Accessibility were visible, with Continue disabled. No new permission was granted. After quitting, root confirmed the fork's `hasCompletedOnboardingV2` key was absent, then received execution approval to seed only that temporary app preference for file testing and restore it afterward. This is seeded navigation, not completed permission onboarding. Root imported the checksum-verified Tiny English `.bin` through the actual model-import dialog and observed Downloaded. A default Local Dictation mode was created with enhancement off. Its initial native selection was Apple Speech; that provider transcribed the seven-second fixture inside the app with exact expected punctuation and text. History contained the full result, and after quitting/relaunching the dashboard Recent Transcripts still showed it. No commercial prefix or credential prompt appeared. Whisper-in-app verification is pending the final accessible picker build; separate Whisper CLI already passed.

Native UX follow-up: selected sidebar text still used white on the mint system selection, and the borderless model Menu was absent as an interactive AX control. The app writer corrected two Swift files only: explicit measured selected fill/foreground and clearing stale selected traits in AppSidebar, plus model Menu label/value/stable identifier and contained row semantics in ModeConfigFormView. Frozen tests and full Swift parse still pass; final rebuilt native checks remain to be observed.

Pre-existing bundled VAD exception: `VoiceInk/Resources/models/ggml-silero-v5.1.2.bin` was already tracked and bundled upstream and is required by VADModelManager. It is 885,098 bytes, SHA256 `29940d98d42b91fbd05ce489f3ecf7c72f0a42f027e4875919a28fb4c04ea2cf`, matching ggml-org/whisper-vad revision `9ffd54a1e1ee413ddf265af9913beaf518d1639b`. Original Silero v5.1.2 revision `6478567951ae5c9979ad7b234185b5515f4be7a1` is MIT. B5 now states this preserved, verified exception; no newly downloaded transcription/Refine weights are tracked or packaged. Builder owns exact notice/card updates; docs must describe this accurately.

## Open items for the user

- Review the Robey Voice name, teal waveform icon and theme.
- Approve normal macOS Microphone and Accessibility permissions, then validate microphone dictation and paste/shortcuts. No permission grants were made unattended.
- For routine distribution to other Macs, provide a usable Developer ID Application identity and notarization profile, then build/notarize and perform a normal second-Mac installation. This review artifact is Apple Development signed and not notarized.
- Confirm hardware targets beyond the verified Apple silicon host; Intel, macOS 15 hardware, lower-memory configurations, and full VoiceOver/focus acceptance remain unverified.

## Lessons and open items

Final build/package checkpoint, November 17: the standard `.review-build/DerivedData` Release build succeeded; all 18 real-artifact tests passed with no skips in 18.290 seconds. The alternative FinalDerivedData request was aborted and never built; it supplies no validation evidence. Final source binding begins `399d83be` and app binding `c1b6dfa3`. Independent package verification passed all five checksum entries, all 526 source file hashes, 16 dependency notice files, exact staged/built app equality across 100 entries, deep/strict and individual Mach-O signatures outside the sandbox, and DMG integrity VALID. `make -n release` with custom DerivedData confirms the corresponding build-record handoff. The final source archive will be refreshed after closing documentation and orchestration outputs; the tested app and DMG remain frozen.

Final native CUA checkpoint: normal Finder reopening recovered the running app's absent window. The corrected model picker exposed label `Transcription Model`, current value, and identifier `transcription-model-picker`; selecting Tiny (English) and saving the Local Dictation mode succeeded. Actual final-app Whisper file transcription of the valid seven-second synthetic WAV returned exactly: “This is a local transcription test. The quick brown fox jumps over the lazy dog. No subscription is required.” Both this result and the earlier Apple Speech result appeared in Recent Transcripts after quit/relaunch. No cloud credentials, purchase text, or security permission grants were used. Root quit the app, deleted only the temporary fork onboarding flag (exit 0), relaunched and observed the original permissions screen with Microphone Allow, locked Accessibility, and Continue disabled. App was then quit and absent from running inventory. Temporary onboarding state is restored; task-owned model/mode and two synthetic history records remain isolated in the fork. Real microphone, paste/shortcut permission, second-Mac, Intel, macOS 15 hardware, VoiceOver/focus and branding acceptance remain human checks.

Review coverage decision: migration/schema review is inapplicable because no database schema or serialized settings version changes were introduced. Isolation and explicit settings-transfer behavior were reviewed through architecture, security, reliability and operations; there is no automatic upstream data migration to validate. Native CUA supplies UI verification; browser testing remains inapplicable.

Final operations/documentation refresh: PASS, no unresolved operations blocker. The prior medium custom DerivedData record mismatch is resolved at Makefile:19 and was independently checked with `make -n release LOCAL_DERIVED_DATA=...AlternateData`. Current documentation accurately records the final standard DerivedData build, package, native results and restored test preference. Narrow accessibility refresh passes the two corrected files and native picker behavior. Remaining nonblocking findings have owners: low imported-Refine shortcut fallback explanation (application maintenance), info semantic-red/full focus/pressed/VoiceOver checks (application accessibility maintenance/Jason). Security package review's prior two low/two info findings were resolved. Closing technical review is now underway against all Expectations, edge cases, Boundaries and Deliverables; its report and local PR draft remain pending orchestration outputs.

Closing-review correction: the technical reviewer found a medium EC4 blocker in inherited Whisper model discovery/import/download: any `.bin` could be shown Downloaded/selectable before native load failed, with readiness retained after failure. This violates the explicit invalid-model requirement despite being pre-existing. A fresh-context independent test author is adding a separate immutable behavioral suite for the public validator contract before the scoped app writer repairs it. Existing four frozen tests remain unchanged. The previous app/package checks remain historical evidence; final build, artifact checks, native valid/invalid import, provenance, source archive and package must be refreshed after this repair before closure.

Independent invalid-model RED: fresh author ran `python3 -B -m unittest discover -s Tests/PersonalForkAcceptance -p test_whisper_model_validation.py -v`, 2 tests in 15.034 seconds, exit 1. The real checksummed Tiny English fixture loaded through CPU-only native no-state calibration; the production contract failed by assertion solely because the promised validator source was absent. Root inspected both new test files before authorizing source writes. They cover real-model acceptance and 23 corrupt/truncated/header/tensor cases with explicit valid/invalid exit semantics, bounded time/RSS/output, and no network, microphone or private input. App repair ownership is limited to the new validator, WhisperModelManager and minimal project source registration; other files require coordination.

Frozen invalid-model files: `test_whisper_model_validation.py` SHA256 `ed5d50fd4c4412c3d0a9e90f2328c16f9e03319f3cbf5add062b48d3fd128c86`; `whisper_validation_main.swift` SHA256 `6fb1bd6d7b2bea727280b17aff5d4df9cc5dbe16f580af905187015788ecfb58`. Test author released both files before implementation. The closing reviewer returned BLOCKED solely for the medium EC4 finding, with all other E/EC/B/D coverage reviewed; that result must be refreshed after correction and new artifact evidence.

First EC4 correction passed the two new behavioral tests in 7.064 seconds. Narrow independent security/reliability review then found a concrete native-compatibility issue in the new permissive header bounds: vocabulary counts beyond 51866 can make the pinned native filler construct a string from an unavailable language name. The writer is paused while the independent author adds a separate coherent-model vocabulary regression; no existing frozen test is edited. The same follow-up will cap cumulative token metadata and add cancellation checks. No native load of the unsupported candidate is authorized or needed; its rejection is tested through the bounded validator API.

Vocabulary regression RED: independent author added only `test_whisper_vocabulary_bounds.py`, SHA256 `4b38f6424dc735bed2d40c5f3107d685f39e67222d08a5c982b22bbe0249f2ec`. One test ran in 2.453 seconds and failed because the production validator returned VALID for a complete, internally consistent Tiny container with unsupported 51867-token header and correspondingly extended embedding matrix. The candidate was never passed to native load. Root inspected this new test; all six prior test hashes remain frozen. The writer is now authorized to tighten the header range and metadata budget, followed by regression rerun and independent security refresh.

Final EC4 source correction: all three new independent tests passed in 9.434 seconds (`.review-build/model-validation-green.log`). Writer supplied full Swift frontend parse and whitespace PASS; root independently verified all seven frozen test hashes unchanged. Narrow independent security/reliability refresh returned PASS, no material findings: native vocabulary guard, 8 MiB aggregate metadata budget, cancellation, expected tensor type/shape/count and payload bounds, safe staged replacement and failure-state invalidation reviewed. Source is released for the final incremental build; a fresh package and native invalid-discovery/import and valid-transcription evidence remain required. Validator SHA256 `c7d1855ae7bd6258e69a57d6fc92a5945aca7b37b4e31e32cc986e86e62feb8b`.

Whisper-corrected artifact checkpoint: Release succeeded with source binding `91b2ebe399dca3504e68d5bfd1ba3f884acc487f08af56dc4572dbffc3498204`, app binding `685d3aa516fc10d1fd25f6d835ef5ab52a513b73b4d6ea2e55e03afa354744e8`, and all 21 real-artifact tests passed with no skips in 34.607 seconds. The 530-file source package, five checksums, staged equality and DMG integrity passed. This package becomes historical because the additional setup-latch correction below requires a new build.

Native-session limit and cleanup: after that rebuild, CUA could not obtain windows for either Robey Voice or Finder (`cgWindowNotFound`), including a supported Finder new-window attempt. App inventory showed both running; no crash or product failure was established. Therefore final native invalid-discovery/import checks are unverified. The task-created 36-byte invalid discovery probe had not been observed by UI; root stopped only the task-launched review process, removed only that unchanged probe, deleted the temporary onboarding flag, and independently confirmed process stopped, probe absent and preference originally unset. No TCC or system-security state changed. Earlier actual Apple Speech/Whisper transcription and persistence remain valid historical evidence; the latest repaired UI requires owner/session acceptance.

Complete local-provider EC4 audit identified one further concrete gap: FluidAudio's pending/failed setup marker lived only in memory, so complete-looking cache files could regain Downloaded after restart despite failed native setup. A durable pending/failed latch, written before setup and cleared only on verified success, is now required. Independent store tests precede the narrow repair. TranscribeCpp acquisition already checks exact revision, size and streaming SHA before final commit; native Apple asset readiness uses OS state; restricted Refine remains unavailable. No other acquisition blocker was found. Post-discovery external modification of a model remains a bounded follow-up rather than a promised arbitrary-file integrity service.

Setup-store RED: the fresh independent author added `test_model_setup_readiness.py` (SHA256 `ed65570fc3023d214300e80e961cc05a31e516236bc1b12edbc704ea14d88fc1`) and `model_setup_readiness_main.swift` (SHA256 `753f0ab6a727ea792ad09866c5e4bd103afbf99f91fc3587f8cf6bfd6b79f9bd`). One assertion failed for missing promised source before compilation or preference mutation. Root inspected both files, which use isolated UUID domains and separate begin/status/interrupt/complete processes plus scoped cleanup. All seven prior files remain frozen. Writer scope now also includes the new store, FluidAudio manager, model-card retry label and minimal project registration. No other provider changes are authorized by this correction.

Setup-store correction GREEN: the cross-process test passed in 2.435 seconds (`.review-build/model-setup-readiness-green.log`); full Swift parse and whitespace checks passed. Store uses one injected defaults key, locked set updates and explicit synchronization; no unrelated keys/models are cleared. FluidAudio writes the marker before setup, retains it on interruption/failure, clears it only after branch-specific native checks and final cancellation check, and supplies Resume Download state after restart. All nine test files are now frozen. Final incremental Release and all 22 real-artifact acceptance checks are underway; no new native UI completion is inferred while window access is unavailable.

Final corrected artifact evidence: Release BUILD SUCCEEDED; all 22 real-artifact acceptance tests passed with no skips in 29.538 seconds (`.review-build/acceptance-artifact.log`). Root directly inspected that log and independently verified current build binding: source `da441f50e8d7d07538eb77a1c00e3f066c5cca56b3c730e2479cfe5dd7192804`, app `e5a6dca2c17410c752e7aa1acdda0515b625fd81ef166c705432c91629f5c22a`; whitespace check passed. Narrow FluidAudio security/reliability refresh returned PASS with no material findings. Final package `.review-build/review-package/` has VALID DMG integrity, all five checksums passing, source-file/manifest equality, exact staged/built equality across 100 entries, and staged deep/strict/component signature verification. DMG SHA256 `e052fa52a51aa56f5415beef584c69a15d89d0260624960cdd1ab63b1e0df895`. App and DMG are frozen, Apple Development signed and not notarized. Source archive/checksums alone will be refreshed to include final documentation and orchestration outputs. Latest repaired native UI remains unverified because of the recorded session-window limitation.

Closing technical review: **PASS for the local review build**, after all implementation, 22-test artifact verification, final documentation and matching source snapshot were reviewed. Reviewer independently reverified all 533 then-current source files against manifest/archive, final DMG hash, source/app binding, nine exact clean dependencies, whitespace and test evidence. Coverage includes every E1–E12, EC1–EC10, B1–B9, D1–D6 and automated item. Both EC4 acquisition blockers and the native vocabulary issue are resolved; no unresolved blocker/high/medium finding remains. Low Refine shortcut fallback explanation and informational complete accessibility checks retain the named owners. Latest unavailable UI and human distribution/daily-use checks remain explicitly pending. Closing-review copy, Execution Report, PR draft and final plan entries are now being assembled under the review's explicit orchestration-output exception, followed by the final source-only archive refresh. No IDD lifecycle annotation or human acceptance is implied.

## Local review delivery

All required local implementation and review outputs are saved. Root audited the actual [closing review](../../robey-voice-closing-review.md), [execution report](../../robey-voice-execution-report.md) and [local PR draft](../../robey-voice-pr-draft.md), including full coverage, findings/owners, exact runbook, artifact identities and explicit native/human limits. The PR remains local and the branch remains uncommitted; nothing was pushed or published. The pre-existing repository review is preserved.

The final source-only packaging operation includes these orchestration outputs and this completed checklist. Its canonical verification records are `.review-build/review-package/source-provenance.json` and `SHA256SUMS.txt`; the tested app and DMG stay byte-identical. Report copies retain the 533-file checkpoint as historical closing-review evidence, while final source-archive membership is recorded in its own manifest. No further application or reviewed documentation changes followed the technical PASS.

The daemon restart interrupted only report assembly; root rechecked saved files, the passing 22-test log, current source/app binding, package hashes and restored onboarding preference before resuming the missing outputs. No build, transcription or permission action was blindly repeated.

The review package is ready for Jason's later branding and daily-use acceptance after final source verification. Latest repaired native UI, permissions/microphone/paste, optional large-model/offline/fault scenarios, settings transfer/replacement/rollback, notarization and second-Mac acceptance remain open exactly as listed above and in the validation record.

## Publication authorization — November 20, 2026

Jason explicitly requested that the code be committed, merged into main and released. This supersedes the earlier no-push/no-publication boundary for this delivery; it does not imply completed native/human acceptance or new signing credentials. Live inspection found the local work uncommitted, origin/main still at the reviewed baseline and no GitHub releases. The public destination is Jason's `GrillerGeek/VoiceInkGG` repository, with current authenticated admin/push access confirmed.

Publication checklist:

- [x] Recheck remote/default branch, clean main worktree, reviewed source manifest and app/package build binding.
- [x] Rerun the real-app acceptance checks and audit the exact source staged for publication.
- [ ] Commit and push Customize; create and merge its PR into main without bypassing branch protections.
- [ ] Refresh matching source provenance/checksums against the merged source and publish `v0.1.0` assets.
- [ ] Verify remote main, merged PR, tag and uploaded release assets.

The available binary remains the exact Apple Development-signed arm64 review build. The first public release will be labeled a preview/prerelease because notarization, second-Mac acceptance and the latest repaired UI checks are still pending. No new application or dependency change is needed. Publication changes are confined to download/release documentation and excluding the transient progress lock from source control; existing review reports remain historical checkpoints.

Publication preparation evidence: fresh real-app acceptance passed all 22 checks with no skips in 42.335 seconds (`.review-build/publication-acceptance.log`). All staged source blobs match their reviewed file hashes except the explicitly authorized publication docs/plan; no credential or generated-cache candidates were found. Source/code whitespace checks pass. Full staged whitespace notices are confined to five exact upstream legal/model-notice copies, whose original bytes are intentionally preserved. Origin/main is unprotected and still at the baseline; there are no existing Customize PRs or fork releases to duplicate.

- User is away and delegated routine choices. Continue independent work; do not add optional approval pauses.
- Missing signing access or unavailable second-device UI acceptance must remain explicit while a working local deliverable is pursued.
- Branding approval belongs to Jason after a concrete preview exists.
