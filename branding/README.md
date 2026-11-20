# Robey Voice artwork and notice sources

Original artwork and modifications: Copyright (C) 2026 Jason Robey, November 16, 2026. Artwork and generator are released under GPLv3 with this fork. No upstream VoiceInk visual artwork was used to construct the waveform. No generative raster service was used.

The mark uses five rounded waveform bars in teal (`#6DE7D5`) on an ink gradient (`#173E48` to `#091F2A`). The rounded tile has a transparent outer margin for native macOS presentation. The menu mark is an original black alpha template so macOS controls its light/dark appearance. AccentColor is dark teal (`#00706E`) in light appearance and light teal (`#6DE7D5`) in dark appearance. Provider logos and unrelated image assets are preserved.

Run from the repository root:

```sh
swift -module-cache-path /private/tmp/robey-voice-brand-swift-cache branding/GenerateBrand.swift
python3 branding/CollectDependencyNotices.py
```

The Swift generator uses AppKit vector drawing at each output resolution, producing all 16/32/64/128/256/512/1024 pixel files referenced by the existing app icon catalog and a menu template. The SVG is the editable geometric source; its flat vector content matches the native renderer, with a subtle native shadow added to the rendered tile.

Previews are generated under ignored `.review-build/branding/app-icon.png` and `brand-review.png`. The review sheet shows 16–256 pixel icons on light and dark surfaces. Implementation visual QA has been performed; Jason's branding acceptance remains pending.

`CollectDependencyNotices.py` is an offline collector. It reads the final Package.resolved, verifies available checkouts against their exact pinned revisions, and preserves tracked license/copying/notice/copyright files and SHA-256 values. It never fetches or copies weights, API keys, or user data. Missing package checkouts remain explicitly pending in the bundled dependency inventory. Re-run it after the builder resolves the final dependency graph.

The GPL license was obtained verbatim from https://www.gnu.org/licenses/gpl-3.0.txt on 2026-11-16. Root LICENSE and Legal/GPL-3.0.txt are byte-identical. Model source revisions, restrictions, and exact notice URLs are recorded in Legal/THIRD_PARTY_NOTICES.md. Source cards are preserved under Legal/Models; no model weights are bundled.
