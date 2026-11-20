"""WCAG AA body-label contrast against the configured light/dark accent.

Run: python3 -B -m unittest discover -s Tests/PersonalForkAcceptance -p test_brand_contrast.py -v
The theme is an opaque compiler input; the asset catalog is runtime fixture data.
Only task-owned temporary compiler outputs are written. No app/data/permissions,
network or microphone access occurs. Pressed/focus/VoiceOver and human branding
acceptance require separate native UI evidence.
"""

import json
import math
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


def opaque_rgba(value):
    channels = tuple(float(value[key]) for key in ("red", "green", "blue", "alpha"))
    if not all(math.isfinite(channel) and 0 <= channel <= 1 for channel in channels):
        raise ValueError(f"Invalid sRGB channels: {channels}")
    if channels[3] != 1:
        raise ValueError(f"Transparent color requires a defined compositing background: {channels}")
    return channels


def contrast(first, second):
    def luminance(value):
        red, green, blue, _ = opaque_rgba(value)
        linear = [channel / 12.92 if channel <= 0.04045
                  else ((channel + 0.055) / 1.055) ** 2.4
                  for channel in (red, green, blue)]
        return sum(channel * weight for channel, weight in zip(linear, (0.2126, 0.7152, 0.0722)))
    low, high = sorted((luminance(first), luminance(second)))
    return (high + 0.05) / (low + 0.05)


def catalog_colors(catalog):
    """Resolve the ordinary Aqua fallback and explicit Dark Aqua catalog entries."""
    choices = {"light": [], "dark": []}
    for entry in catalog["colors"]:
        if entry.get("idiom") not in ("universal", "mac"):
            continue
        appearances = entry.get("appearances", [])
        if appearances == []:
            choices["light"].append(entry)
        elif appearances == [{"appearance": "luminosity", "value": "dark"}]:
            choices["dark"].append(entry)
        elif appearances == [{"appearance": "luminosity", "value": "light"}]:
            raise ValueError("Explicit light plus fallback appearance selection needs fixture support")
        else:
            raise ValueError(f"Unsupported accent appearance selection: {appearances}")
    result = {}
    for appearance, entries in choices.items():
        if len(entries) != 1:
            raise ValueError(f"Expected one unambiguous {appearance} accent fixture, got {len(entries)}")
        color = entries[0]["color"]
        if color.get("color-space") != "srgb":
            raise ValueError(f"Accent fixture is not sRGB: {color.get('color-space')}")
        def component(value):
            return int(value, 16) / 255 if isinstance(value, str) and value.lower().startswith("0x") else float(value)
        result[appearance] = {key: component(color["components"][key])
                              for key in ("red", "green", "blue", "alpha")}
        opaque_rgba(result[appearance])
    return result


def gray(value, alpha=1):
    return dict(red=value, green=value, blue=value, alpha=alpha)


class ContrastFixtureTests(unittest.TestCase):
    def test_black_white_and_identical_reference_ratios(self):
        self.assertAlmostEqual(contrast(gray(0), gray(1)), 21)
        self.assertEqual(contrast(gray(0.5), gray(0.5)), 1)
        self.assertEqual(contrast(gray(1), gray(0)), contrast(gray(0), gray(1)))

    def test_known_colors_straddle_aa_body_threshold(self):
        self.assertGreaterEqual(contrast(gray(118 / 255), gray(1)), 4.5)
        self.assertLess(contrast(gray(119 / 255), gray(1)), 4.5)

    def test_transparency_is_explicit_fixture_error(self):
        with self.assertRaisesRegex(ValueError, "compositing"):
            contrast(gray(0, 0.5), gray(1))

    def test_invalid_channels_are_explicit_fixture_error(self):
        for channel in (-0.01, 1.01, float("nan")):
            with self.subTest(channel=channel), self.assertRaises(ValueError):
                contrast(gray(channel), gray(1))

    def test_catalog_parses_runtime_decimal_and_hex_components(self):
        def entry(value, appearances=None):
            fixture = {"idiom": "universal", "color": {"color-space": "srgb",
                       "components": dict(red=value, green=value, blue=value, alpha="1.000")}}
            if appearances:
                fixture["appearances"] = appearances
            return fixture
        parsed = catalog_colors({"colors": [entry("0.000"), entry("0xFF", [
            {"appearance": "luminosity", "value": "dark"}])]})
        self.assertEqual(parsed, {"light": gray(0), "dark": gray(1)})


class BrandContrastTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if shutil.which("swiftc") is None:
            raise RuntimeError("Harness unavailable: swiftc is required")
        with tempfile.TemporaryDirectory(prefix="robey-voice-contrast-") as directory:
            directory = Path(directory)
            binary = directory / "contrast"
            compiled = subprocess.run([
                "swiftc", "-parse-as-library", "-module-cache-path", str(directory / "module-cache"),
                str(ROOT / "VoiceInk/DesignSystem/Theme/AppTheme.swift"),
                str(Path(__file__).with_name("contrast_main.swift")), "-o", str(binary)
            ], cwd=ROOT, text=True, capture_output=True, timeout=120)
            if compiled.returncode:
                # Preserve diagnostic reasons without exposing opaque subject source excerpts.
                diagnostics = "\n".join(line for line in compiled.stderr.splitlines()
                                        if re.search(r"(?:error|warning):", line))
                raise RuntimeError(f"Harness compilation failed (exit {compiled.returncode}):\n{diagnostics}")
            executed = subprocess.run([str(binary)], cwd=ROOT, text=True, capture_output=True, timeout=30)
            if executed.returncode:
                raise RuntimeError(f"Harness execution failed (exit {executed.returncode}): {executed.stderr}")
            cls.resolved = json.loads(executed.stdout)
        # Calibrate the same SwiftUI -> NSColor bridge under current drawing appearance.
        # A broken bridge is a harness error, never a contrast assertion failure.
        for appearance, dynamic in (("light", 0), ("dark", 1)):
            for key, expected in (("dynamicBridge", dynamic), ("blackBridge", 0), ("whiteBridge", 1)):
                observed = opaque_rgba(cls.resolved[appearance][key])
                if any(abs(a - b) > 1e-6 for a, b in zip(observed, (expected, expected, expected, 1))):
                    raise RuntimeError(f"Non-deterministic appearance bridge: {appearance} {key} {observed}")
        with (ROOT / "VoiceInk/Assets.xcassets/AccentColor.colorset/Contents.json").open() as stream:
            cls.accents = catalog_colors(json.load(stream))

    def check_appearance(self, appearance):
        foreground = self.resolved[appearance]["foreground"]
        accent = self.accents[appearance]
        ratio = contrast(foreground, accent)
        evidence = (f"{appearance}: foreground sRGB={opaque_rgba(foreground)}, "
                    f"accent sRGB={opaque_rgba(accent)}, contrast={ratio:.6f}:1")
        print(evidence, flush=True)
        self.assertGreaterEqual(ratio, 4.5, evidence + "; body labels require WCAG AA >=4.5:1")

    def test_aqua_accent_body_label_contrast(self):
        self.check_appearance("light")

    def test_dark_aqua_accent_body_label_contrast(self):
        self.check_appearance("dark")


if __name__ == "__main__":
    unittest.main()
