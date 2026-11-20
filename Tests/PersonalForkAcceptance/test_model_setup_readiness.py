"""Persistent retry readiness through the public, Foundation-only setup store API.

Run: python3 -B -m unittest discover -s Tests/PersonalForkAcceptance -p test_model_setup_readiness.py -v

The production source is an opaque Swift compiler input. Every probe starts a new
process, using UUID-named synthetic UserDefaults suites only. Cleanup removes only
those task-owned domains. No model weights, native Whisper, application settings,
user data, microphone or network are accessed. A missing promised API produces an
assertion failure before compilation or any preferences mutation.
"""

import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
import uuid

ROOT = Path(__file__).resolve().parents[2]
SUBJECT = ROOT / "Shared/ModelSetupReadinessStore.swift"
HARNESS = Path(__file__).with_name("model_setup_readiness_main.swift")


class ModelSetupReadinessTests(unittest.TestCase):
    def test_retry_state_survives_processes_and_completion_is_scoped(self):
        self.assertTrue(SUBJECT.is_file(),
                        "Promised Foundation-only Shared/ModelSetupReadinessStore.swift is missing; "
                        "provide init(defaults:key:), requiresRetry(for:), beginSetup(for:), "
                        "and completeSetup(for:)")
        self.assertIsNotNone(shutil.which("swiftc"), "Swift compiler is required for the public API")
        with tempfile.TemporaryDirectory(prefix="robey-model-setup-readiness-") as temporary:
            directory = Path(temporary)
            binary = directory / "model-setup-readiness"
            compiled = subprocess.run([
                "swiftc", "-parse-as-library", "-module-cache-path", str(directory / "module-cache"),
                str(SUBJECT), str(HARNESS), "-o", str(binary),
            ], cwd=ROOT, text=True, capture_output=True, timeout=120)
            diagnostics = "\n".join(line for line in compiled.stderr.splitlines()
                                    if "error:" in line or "warning:" in line)
            self.assertEqual(compiled.returncode, 0,
                             f"Public readiness-store compile contract failed:\n{diagnostics}")
            suites = ["com.robeyvoice.acceptance.model-setup." + str(uuid.uuid4()) for _ in range(2)]
            key, other_key = "synthetic.setup-readiness", "synthetic.other-readiness"

            def probe(operation, model="", suite=None, storage_key=key, expected_exit=0):
                executed = subprocess.run([
                    str(binary), suite or suites[0], storage_key, operation, model,
                ], cwd=ROOT, text=True, capture_output=True, timeout=15)
                self.assertEqual(executed.returncode, expected_exit,
                                 f"{operation}({model!r}) failed: {executed.stderr}")
                return json.loads(executed.stdout)

            def retry(model, expected, suite=None, storage_key=key):
                self.assertEqual(probe("status", model, suite, storage_key),
                                 {"requiresRetry": expected},
                                 f"Unexpected retry state for {model!r}, key={storage_key!r}")

            try:
                for suite in suites:
                    probe("seed", suite=suite)
                retry("Tiny English", False)
                retry("Base English", False)
                probe("begin", "Tiny English")
                retry("Tiny English", True)
                retry("Tiny English", True)  # Another recreation cannot clear unfinished setup.
                retry("Base English", False)
                self.assertEqual(probe("begin-and-interrupt", "Base English", expected_exit=75),
                                 {"interrupted": True})
                retry("Base English", True)  # Failure/cancellation supplied no completion.
                retry("Tiny English", True)

                # A different key and a different domain start independently.
                retry("Tiny English", False, storage_key=other_key)
                retry("Tiny English", False, suite=suites[1])
                probe("begin", "Tiny English", storage_key=other_key)
                probe("begin", "Tiny English", suite=suites[1])
                probe("complete", "Tiny English")
                retry("Tiny English", False)
                retry("Base English", True)
                retry("Tiny English", True, storage_key=other_key)
                retry("Tiny English", True, suite=suites[1])
                probe("complete", "never begun")
                retry("Base English", True)
                probe("complete", "Tiny English", storage_key=other_key)
                retry("Tiny English", False, storage_key=other_key)
                retry("Base English", True)
                probe("complete", "Base English")
                retry("Base English", False)
                retry("Tiny English", True, suite=suites[1])
                probe("complete", "Tiny English", suite=suites[1])
                retry("Tiny English", False, suite=suites[1])

                for suite in suites:
                    self.assertEqual(probe("unrelated", suite=suite), {
                        "string": "keep this synthetic value", "bool": True,
                        "array": ["first", "second"],
                    }, "Setup readiness must preserve unrelated defaults")
            finally:
                # Attempt both isolated cleanups even if a behavior assertion fails.
                cleanup_errors = []
                for suite in suites:
                    try:
                        probe("cleanup", suite=suite)
                    except Exception as error:
                        cleanup_errors.append(f"{suite}: {error}")
                self.assertFalse(cleanup_errors, "Synthetic domain cleanup failed: " + "; ".join(cleanup_errors))


if __name__ == "__main__":
    unittest.main()
