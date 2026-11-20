# Robey Voice — upstream, dependency, and model notices

Notice date: November 16, 2026.

Robey Voice is a modified fork of **VoiceInk**, by **Prakash Joshi (Beingpax) and contributors**. Original authorship and copyright attribution are retained. Upstream source: https://github.com/Beingpax/VoiceInk. Baseline source revision: `b5d1be9a7c7377dd059f37bb3e0f791b802d4001`.

Robey Voice modifications and original waveform artwork: Copyright (C) 2026 Jason Robey. Modified November 16, 2026: independent app identity and data isolation, unrestricted local use, manual updates, local defaults, new icon/accent, build/release preparation, and these notices. Original upstream rights remain with their respective owners. This app is distributed under GNU GPL version 3; the complete verbatim license is included as `GPL-3.0.txt` and in the matching source archive as `LICENSE`. There is no warranty as provided in that license. Trademark/provider names identify their original sources and do not imply endorsement.

## Application dependencies

The [dependency inventory](DEPENDENCY_INVENTORY.md) records every package in the checked-in Package.resolved and the native whisper.cpp dependency, exact source revisions, verification state, and full retained license/notice files under `Dependencies/`. `DEPENDENCY_INVENTORY.json` includes SHA-256 values. Items explicitly marked **PENDING** have not yet had exact-revision license files verified; they must be resolved before describing this as a complete third-party distribution review. Re-run the offline collector after final build package resolution. Packages and model licenses are separate from the app's GPLv3 grant.

Native **whisper.cpp**: ggml authors, MIT license, verified checkout `2eeeba56e9edd762b4b38467bab96c2517163158` (v1.8.3), https://github.com/ggml-org/whisper.cpp. Full original license is retained in `Dependencies/whisper.cpp/LICENSE`.

## Bundled VAD and separately downloaded transcription models

The existing Silero VAD detector described below is bundled. Transcription and Refine model weights are not bundled; this notice directory contains attribution text only. Downloaded/custom models and remote services retain their own terms. The following primary paths were checked on the notice date. This does not establish clearance for every optional model in the catalog, arbitrary custom models, remote provider terms, training data, or later mutable downloads.

### Bundled Silero VAD v5.1.2

The app and matching source include the existing `ggml-silero-v5.1.2.bin` voice-activity detector (885,098 bytes), Copyright (c) 2020-present Silero Team, MIT license. Its SHA-256 is `29940d98d42b91fbd05ce489f3ecf7c72f0a42f027e4875919a28fb4c04ea2cf`. The bytes exactly match the Git LFS pointer at GGML conversion revision `9ffd54a1e1ee413ddf265af9913beaf518d1639b`: https://huggingface.co/ggml-org/whisper-vad/blob/9ffd54a1e1ee413ddf265af9913beaf518d1639b/ggml-silero-v5.1.2.bin. Its [model card](Models/Silero-VAD-GGML-model-card.md) declares MIT and identifies conversion to GGML for whisper.cpp. Original source tag v5.1.2: https://github.com/snakers4/silero-vad/tree/6478567951ae5c9979ad7b234185b5515f4be7a1. The complete [MIT license](Models/Silero-VAD-LICENSE.txt) is retained from that exact source revision. Robey Voice preserves the upstream-bundled conversion without changing its bytes; this is the only model weight intentionally included in the app/source review artifacts.

### Whisper

Original **OpenAI Whisper**: Copyright (c) 2022 OpenAI, MIT license. License checked at source revision `86098128c0b4f24f0e2aa2994de830614b474227`; full text: [Whisper-OpenAI-LICENSE.txt](Models/Whisper-OpenAI-LICENSE.txt). Exact source URL: https://raw.githubusercontent.com/openai/whisper/86098128c0b4f24f0e2aa2994de830614b474227/LICENSE.

The app downloads GGML conversions from **ggerganov/whisper.cpp** on Hugging Face. Its model card declares MIT and identifies conversion from OpenAI Whisper. Verified model-card revision `5359861c739e955e79d9a303bcbc70fb988958b1`: https://huggingface.co/ggerganov/whisper.cpp/blob/5359861c739e955e79d9a303bcbc70fb988958b1/README.md. Card retained as [Whisper-cpp-model-card.md](Models/Whisper-cpp-model-card.md). The app's downloader uses mutable `main`, so this verifies the card at the notice date, **not** the exact weight revision of a later installed model. Third-party fine-tunes such as Distil-Whisper, custom Whisper models, and VAD models require separate terms/provenance review.

### Parakeet v3

Original **NVIDIA Parakeet TDT 0.6B v3**, NVIDIA, licensed **CC BY 4.0**. Verified upstream card revision `541d1f99c6b0c3cd0b11a95167540bb8edefd82b`: https://huggingface.co/nvidia/parakeet-tdt-0.6b-v3/blob/541d1f99c6b0c3cd0b11a95167540bb8edefd82b/README.md. Full card retained as [Parakeet-v3-NVIDIA-model-card.md](Models/Parakeet-v3-NVIDIA-model-card.md).

**FluidInference/parakeet-tdt-0.6b-v3-coreml** is a CoreML conversion by Fluid Inference; its card identifies the NVIDIA source and declares **CC BY 4.0**. Verified card revision `7dd20fe6b1797d35f5e3307e8b1732d9a178edfe`: https://huggingface.co/FluidInference/parakeet-tdt-0.6b-v3-coreml/blob/7dd20fe6b1797d35f5e3307e8b1732d9a178edfe/README.md. Card retained as [Parakeet-v3-CoreML-model-card.md](Models/Parakeet-v3-CoreML-model-card.md). Conversion changes the original checkpoint's representation to CoreML; this fork has not modified or redistributed those weights.

Attribution is to NVIDIA for the original model and Fluid Inference for conversion. License: https://creativecommons.org/licenses/by/4.0/; full legal text retained as [CC-BY-4.0.txt](Models/CC-BY-4.0.txt). Original and conversion source links above identify the work and changes. The FluidAudio runtime may fetch mutable model revisions: exact installed weight provenance remains a runtime/download verification item. Parakeet v2/Ultra/unified, Nemotron, and other optional model variants are **not covered by this v3 verification** and require their own model cards and license review before redistribution or a complete catalog clearance claim.

### VoiceInk Refine V1 — unavailable in this fork

External model name: **VoiceInk Refine V1**, beingpax. Model source: https://huggingface.co/beingpax/VoiceInk-Refine-V1. Exact revision referenced by upstream app source and inspected here: `ad665418d3850e379e29236e66be3ddc0ac0bf04`.

Its [LICENSE.md](Models/VoiceInk-Refine-V1-LICENSE.md) grants use only with the VoiceInk application and prohibits commercial use, redistribution, and use in other software or open-source projects without copyright holder permission. Copyright (c) 2026 beingpax; all rights reserved. **Robey Voice does not install or execute this model. Explicit permission would be required before enabling it.** The app's GPLv3 license does not override these separate model restrictions. No Refine weights are included.

The model's [third-party notice](Models/VoiceInk-Refine-V1-THIRD_PARTY_NOTICES.md) identifies **Qwen3.5-2B**, copyright 2026 Alibaba Cloud, as its Apache-2.0 upstream, with text-only MLX conversion and 4-bit quantization. Retained upstream license: [VoiceInk-Refine-V1-QWEN-APACHE-2.0.txt](Models/VoiceInk-Refine-V1-QWEN-APACHE-2.0.txt). Qwen source: https://huggingface.co/Qwen/Qwen3.5-2B. Apache terms for Qwen do not replace the separately supplied Refine package restrictions.

Exact files verified: https://huggingface.co/beingpax/VoiceInk-Refine-V1/blob/ad665418d3850e379e29236e66be3ddc0ac0bf04/LICENSE.md and `THIRD_PARTY_NOTICES.md` / `LICENSE-QWEN-APACHE-2.0.txt` at the same revision. These notice texts are retained for provenance, not as an assertion that Refine use is permitted.
