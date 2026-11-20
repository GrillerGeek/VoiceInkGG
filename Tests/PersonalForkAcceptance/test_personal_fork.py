"""Independent checks derived solely from the standalone Robey Voice Spec.

Run: python3 -m unittest discover -s Tests/PersonalForkAcceptance -v
Optional packaged artifact: ROBEY_VOICE_APP="/absolute/path/Robey Voice.app" <command>

Evidence limits (a passing source audit does not prove runtime acceptance):
E1/E2/EC1/EC2: expired/fresh state, clock changes, onboarding and exact delivered
text require the native app; no public licensing/transcription test API is promised.
E3: configuration audit checks feeds/keys, not absence of service initialization.
E4/E6/EC7/EC10: executable identity and isolated paths/services are checked here;
actual credential access, explicit import/export, data preservation, reinstall and
coexistence require native validation with synthetic data.
E5/EC4/EC5/EC6/EC8: defaults, provider availability, invalid/downloaded models,
permissions and explicitly configured external features require native validation.
E7: resolution revisions are checked; the documented native build must separately
prove workspace-owned outputs and no silent native dependency update.
E8/E12/EC9: optional artifact checks inspect actual architecture and signature;
notarization, supported hardware, source provenance/checksums and distribution
claims require the release evidence. Signature validity alone is not notarization.
E9/E11/EC3: native synthetic transcription, persistence, offline behavior, optional
service failures and operational safeguards remain native acceptance requirements.
E10: these tests supply focused regression coverage; documentation, checklist and
validation-record completeness remain review requirements.

The tests never access Keychain, Application Support, microphone, TCC or network.
Only compiler-created temporary files are written. No implementation is imported
into Python; the promised Foundation-only identity source is compiled in isolation.
"""

import json
import os
from pathlib import Path
import plistlib
import re
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
UPDATER_KEYS = {"SUFeedURL", "SUPublicEDKey", "SUPublicDSAKeyFile"}
# First-release scope clarified by the specification owner: manual updates and
# local storage use no CloudKit or APNs capability. Other entitlements are retained.
UNUSED_CLOUD_ENTITLEMENTS = {
    "com.apple.developer.icloud-container-identifiers",
    "com.apple.developer.icloud-services",
    "com.apple.developer.ubiquity-container-identifiers",
    "com.apple.developer.ubiquity-kvstore-identifier",
    "com.apple.developer.icloud-container-environment",
    "aps-environment", "com.apple.developer.aps-environment",
}
COMMERCIAL_TYPES = {"LicenseViewModel", "LicenseManager", "PolarService"}


def run(*args):
    return subprocess.run(args, cwd=ROOT, text=True, capture_output=True, timeout=120)


def configured_updater_keys(value):
    if isinstance(value, dict):
        result = set(value) & UPDATER_KEYS
        for child in value.values():
            result |= configured_updater_keys(child)
        return result
    if isinstance(value, list):
        return set().union(*(configured_updater_keys(child) for child in value))
    return set()


def swift_executable_identifiers(source):
    """Lexical audit: ignore comments (including nesting), strings and raw strings.

    String interpolation is intentionally opaque; native execution still needs
    verification. This checks direct type dependencies, not arbitrary enforcement.
    """
    code = []
    index = 0
    while index < len(source):
        if source.startswith("//", index):
            end = source.find("\n", index)
            index = len(source) if end < 0 else end
        elif source.startswith("/*", index):
            depth = 1
            index += 2
            while index < len(source) and depth:
                if source.startswith("/*", index):
                    depth += 1
                    index += 2
                elif source.startswith("*/", index):
                    depth -= 1
                    index += 2
                else:
                    index += 1
            code.append(" ")
        else:
            literal = re.match(r'(#+)?("{3}|")', source[index:])
            if literal:
                hashes = literal.group(1) or ""
                quotes = literal.group(2)
                index += len(literal.group(0))
                closing = quotes + hashes
                escape = "\\" + hashes
                while index < len(source):
                    if source.startswith(escape, index):
                        index += len(escape) + 1
                    elif source.startswith(closing, index):
                        index += len(closing)
                        break
                    else:
                        index += 1
                code.append(" ")
            else:
                code.append(source[index])
                index += 1
    return set(re.findall(r"[A-Za-z_][A-Za-z0-9_]*", "".join(code)))


class AuditFixtureTests(unittest.TestCase):
    def test_lexical_audit_ignores_notices_strings_and_nested_comments(self):
        fixture = r'''// LicenseManager copyright notice
/* PolarService /* LicenseViewModel */ legal notice */
let ordinary = "LicenseManager \" PolarService"
let multiline = """LicenseViewModel"""
let raw = ##"PolarService \##" LicenseManager"##
let rawMultiline = #"""LicenseManager"""#
let service: ActualService = ActualService()
'''
        self.assertFalse(swift_executable_identifiers(fixture) & COMMERCIAL_TYPES)
        for identifier in COMMERCIAL_TYPES:
            self.assertIn(identifier, swift_executable_identifiers("let dependency: " + identifier))
        self.assertIn("ActualService", swift_executable_identifiers(fixture))


class IdentityContractTests(unittest.TestCase):
    snapshots = None

    def identities(self):
        source = ROOT / "Shared/AppIdentity.swift"
        self.assertTrue(source.is_file(), "Promised Foundation-only Shared/AppIdentity.swift is missing")
        self.assertIsNotNone(shutil.which("swiftc"), "Swift compiler is required to verify the identity contract")
        if type(self).snapshots is None:
            snapshots = {}
            with tempfile.TemporaryDirectory(prefix="robey-voice-identity-") as directory:
                directory = Path(directory)
                # Swift permits top-level executable statements in a file named main.swift.
                harness = directory / "main.swift"
                shutil.copyfile(Path(__file__).with_name("identity_main.swift"), harness)
                for configuration, flags in (("Debug", ["-D", "DEBUG"]), ("Release", ["-O"])):
                    binary = directory / configuration
                    compiled = run("swiftc", "-module-cache-path", str(directory / "module-cache"),
                                   *flags, str(source), str(harness), "-o", str(binary))
                    self.assertEqual(compiled.returncode, 0,
                                     f"{configuration} identity source failed its public compile contract:\n{compiled.stderr}")
                    executed = run(str(binary))
                    self.assertEqual(executed.returncode, 0, f"{configuration} identity harness failed: {executed.stderr}")
                    snapshots[configuration] = json.loads(executed.stdout)
            type(self).snapshots = snapshots
        return type(self).snapshots

    def test_display_and_helper_identity_match_public_contract(self):
        for configuration, identity in self.identities().items():
            with self.subTest(configuration=configuration):
                self.assertEqual(identity["displayName"], "Robey Voice")
                self.assertEqual(identity["refineXPCServiceName"], "com.jasonrobey.RobeyVoice.RefineXPC")

    def test_release_identifier_is_stable_for_replacement_installations(self):
        for configuration, identity in self.identities().items():
            with self.subTest(configuration=configuration):
                self.assertEqual(identity["productionBundleIdentifier"], "com.jasonrobey.RobeyVoice")
                self.assertEqual(identity["developmentBundleIdentifier"], "com.jasonrobey.RobeyVoice.dev")
        self.assertEqual(self.identities()["Release"]["bundleIdentifier"], "com.jasonrobey.RobeyVoice")

    def test_debug_and_release_data_and_credentials_are_isolated(self):
        snapshots = self.identities()
        self.assertEqual(snapshots["Debug"]["bundleIdentifier"], "com.jasonrobey.RobeyVoice.dev")
        for configuration, identity in snapshots.items():
            with self.subTest(configuration=configuration):
                self.assertEqual(identity["applicationSupportDirectoryName"], identity["bundleIdentifier"])
                self.assertEqual(identity["keychainServiceName"], identity["bundleIdentifier"])
                self.assertEqual(identity["logSubsystem"], identity["bundleIdentifier"].lower())
                # Use paths without touching either application's real data.
                base = Path("/synthetic/Library/Application Support")
                support = base / identity["applicationSupportDirectoryName"]
                self.assertEqual(support.parent, base)
                self.assertNotEqual(support, base / "VoiceInk")
        for key in ("bundleIdentifier", "applicationSupportDirectoryName", "keychainServiceName", "logSubsystem"):
            self.assertNotEqual(snapshots["Debug"][key], snapshots["Release"][key], key)

    def test_public_runtime_identities_do_not_reuse_upstream_identity(self):
        for configuration, identity in self.identities().items():
            for property_name, value in identity.items():
                with self.subTest(configuration=configuration, property=property_name):
                    self.assertNotIn("voiceink", value.lower())


class RepositoryConfigurationTests(unittest.TestCase):
    def tracked_paths(self):
        result = run("git", "ls-files", "-z")
        self.assertEqual(result.returncode, 0, "Cannot inventory tracked configuration")
        return [ROOT / name for name in result.stdout.split("\0") if name]

    def test_no_updater_feed_or_public_key_is_configured(self):
        violations = []
        for path in self.tracked_paths():
            if not path.is_file() or "Tests" in path.relative_to(ROOT).parts:
                continue
            keys = set()
            if path.suffix == ".plist":
                with path.open("rb") as stream:
                    keys = configured_updater_keys(plistlib.load(stream))
            elif path.suffix in {".pbxproj", ".xcconfig"}:
                text = path.read_text()
                keys = {key for key in UPDATER_KEYS
                        if re.search(r"\b(?:INFOPLIST_KEY_)?" + re.escape(key) + r"\s*=", text)}
            if keys:
                violations.append(f"{path.relative_to(ROOT)}: {', '.join(sorted(keys))}")
        self.assertFalse(violations, "Upstream updater configuration remains:\n" + "\n".join(violations))

    def test_first_release_has_no_cloudkit_or_push_entitlements(self):
        violations = []
        entitlements = [path for path in self.tracked_paths()
                        if path.suffix == ".entitlements" and path.is_file()]
        for path in entitlements:
            with path.open("rb") as stream:
                values = plistlib.load(stream)
            configured = set(values) & UNUSED_CLOUD_ENTITLEMENTS
            if configured:
                violations.append(f"{path.relative_to(ROOT)}: {', '.join(sorted(configured))}")
        self.assertFalse(violations, "Unused first-release cloud capabilities remain:\n" + "\n".join(violations))

    def test_executable_swift_has_no_commercial_enforcement_type_dependencies(self):
        violations = []
        for path in self.tracked_paths():
            if path.suffix != ".swift" or not path.is_file() or "Tests" in path.relative_to(ROOT).parts:
                continue
            dependencies = swift_executable_identifiers(path.read_text()) & COMMERCIAL_TYPES
            if dependencies:
                violations.append(f"{path.relative_to(ROOT)}: {', '.join(sorted(dependencies))}")
        self.assertFalse(violations, "Commercial enforcement dependency tokens remain:\n" + "\n".join(violations))

    def test_swift_package_resolution_pins_exact_source_revisions(self):
        locks = [path for path in self.tracked_paths() if path.name == "Package.resolved" and path.is_file()]
        self.assertTrue(locks, "No tracked Swift package resolution is available for reproducible builds")
        for path in locks:
            lock = json.loads(path.read_text())
            pins = lock.get("pins", lock.get("object", {}).get("pins", []))
            self.assertTrue(pins, f"No resolved packages in {path.relative_to(ROOT)}")
            for pin in pins:
                with self.subTest(lock=str(path.relative_to(ROOT)), package=pin.get("identity", pin.get("package"))):
                    self.assertRegex(pin.get("state", {}).get("revision", ""), r"^[0-9a-fA-F]{40}$")


@unittest.skipUnless(os.environ.get("ROBEY_VOICE_APP"), "Set ROBEY_VOICE_APP to verify a real Release application")
class ReleaseArtifactTests(unittest.TestCase):
    def app(self):
        app = Path(os.environ["ROBEY_VOICE_APP"]).expanduser().resolve()
        self.assertTrue(app.is_dir(), "ROBEY_VOICE_APP must identify an existing application bundle")
        return app

    def test_release_bundle_identity_and_updater_configuration(self):
        app = self.app()
        with (app / "Contents/Info.plist").open("rb") as stream:
            info = plistlib.load(stream)
        self.assertEqual(info["CFBundleIdentifier"], "com.jasonrobey.RobeyVoice")
        self.assertEqual(info.get("CFBundleDisplayName", info.get("CFBundleName")), "Robey Voice")
        for path in app.rglob("Info.plist"):
            with path.open("rb") as stream:
                self.assertFalse(configured_updater_keys(plistlib.load(stream)),
                                 f"Updater feed/key configured in artifact: {path.relative_to(app)}")

    def test_executable_and_embedded_macho_architectures_and_signatures(self):
        app = self.app()
        for tool in ("file", "lipo", "codesign"):
            self.assertIsNotNone(shutil.which(tool), f"{tool} is required for artifact verification")
        with (app / "Contents/Info.plist").open("rb") as stream:
            info = plistlib.load(stream)
        executable = app / "Contents/MacOS" / info["CFBundleExecutable"]
        self.assertTrue(executable.is_file(), "Release executable is missing")
        main_archs = run("lipo", "-archs", str(executable))
        self.assertEqual(main_archs.returncode, 0, main_archs.stderr)
        required_archs = set(main_archs.stdout.split())
        self.assertTrue(required_archs & {"arm64", "x86_64"}, "Executable has no supported Mac architecture")
        checked = 0
        for path in app.rglob("*"):
            if not path.is_file() or path.is_symlink():
                continue
            kind = run("file", "-b", str(path))
            self.assertEqual(kind.returncode, 0, f"Cannot classify {path.relative_to(app)}")
            if "Mach-O" not in kind.stdout:
                continue
            checked += 1
            architectures = run("lipo", "-archs", str(path))
            self.assertEqual(architectures.returncode, 0, architectures.stderr)
            self.assertTrue(required_archs <= set(architectures.stdout.split()),
                            f"Embedded component cannot support all app architectures: {path.relative_to(app)}")
            signature = run("codesign", "--verify", "--strict", str(path))
            self.assertEqual(signature.returncode, 0,
                             f"Invalid component signature: {path.relative_to(app)}\n{signature.stderr}")
        self.assertGreater(checked, 0)
        bundle_signature = run("codesign", "--verify", "--deep", "--strict", str(app))
        self.assertEqual(bundle_signature.returncode, 0, bundle_signature.stderr)


if __name__ == "__main__":
    unittest.main()
