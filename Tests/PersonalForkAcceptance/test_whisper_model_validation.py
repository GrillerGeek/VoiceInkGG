"""Independent behavioral acceptance for the public WhisperModelValidator API.

Run: python3 -B -m unittest discover -s Tests/PersonalForkAcceptance -p test_whisper_model_validation.py -v

The production source is an opaque compiler input. Fixtures derive from the pinned
whisper.cpp GGML format and the supplied, task-owned Tiny English model; no app
implementation is inspected. Only temporary compiler outputs and synthetic model
copies are written. No network, microphone, user data, GPU or inference is needed.
The native reference calibration explicitly disables GPU. The production validator
must itself keep validation CPU-only. These tests exercise the validation API;
discovery/import/download wiring and ready-state sequencing need separate evidence.
"""

import hashlib
import os
from pathlib import Path
import platform
import shutil
import signal
import struct
import subprocess
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parents[2]
SUBJECT = ROOT / "Shared/WhisperModelValidator.swift"
HARNESS = Path(__file__).with_name("whisper_validation_main.swift")
MODEL = ROOT / ".local-dependencies/models/ggml-tiny.en.bin"
XCFRAMEWORK = ROOT / ".local-dependencies/whisper.cpp/build-apple/whisper.xcframework"
MODEL_SIZE = 77_704_715
MODEL_SHA256 = "921e4cf8686fdd993dcd081a5da5b6c365bfde1162e72b08d75ac75289920b1f"
MIB = 1024 * 1024


def bounded_run(arguments, directory, timeout=30, memory_mib=768):
    """Bound child RSS, time and captured diagnostics, including malformed native inputs."""
    with tempfile.TemporaryFile() as stdout, tempfile.TemporaryFile() as stderr:
        process = subprocess.Popen(arguments, cwd=ROOT, stdout=stdout, stderr=stderr,
                                   start_new_session=True)
        deadline = time.monotonic() + timeout
        violation = None
        try:
            while process.poll() is None:
                if time.monotonic() > deadline:
                    violation = f"exceeded {timeout}s timeout"
                    break
                measured = subprocess.run(["/bin/ps", "-o", "rss=", "-p", str(process.pid)],
                                          capture_output=True, text=True, timeout=3)
                rss = measured.stdout.strip()
                if rss and int(rss) > memory_mib * 1024:
                    violation = f"exceeded {memory_mib} MiB RSS ceiling"
                    break
                time.sleep(0.05)
        finally:
            if process.poll() is None:
                os.killpg(process.pid, signal.SIGKILL)
            process.wait(timeout=5)
        stdout.seek(0)
        stderr.seek(0)
        output = stdout.read(16_384).decode("utf-8", errors="replace")
        diagnostics = stderr.read(16_384).decode("utf-8", errors="replace")
        if violation:
            raise AssertionError(f"Validation harness {violation}; stderr: {diagnostics}")
        return process.returncode, output, diagnostics


def prerequisites(test):
    if platform.system() != "Darwin" or platform.machine() != "arm64":
        test.skipTest("Frozen native validation harness requires macOS arm64")
    if shutil.which("swiftc") is None:
        test.skipTest("Native validation prerequisite absent: swiftc")
    frameworks = sorted(XCFRAMEWORK.glob("macos-*/whisper.framework"))
    frameworks = [path for path in frameworks if "arm64" in path.parent.name]
    if not frameworks or not (frameworks[0] / "whisper").is_file():
        test.skipTest("Frozen arm64 whisper.framework prerequisite absent; do not rebuild/download")
    if not MODEL.is_file():
        test.skipTest("Task-owned Tiny English model prerequisite absent; do not download")
    test.assertEqual(MODEL.stat().st_size, MODEL_SIZE, "Positive model fixture size changed")
    digest = hashlib.sha256()
    with MODEL.open("rb") as stream:
        for chunk in iter(lambda: stream.read(MIB), b""):
            digest.update(chunk)
    test.assertEqual(digest.hexdigest(), MODEL_SHA256, "Positive model fixture checksum changed")
    return frameworks[0].parent


def compile_probe(test, directory, framework_parent, reference=False):
    binary = directory / ("reference" if reference else "validator")
    arguments = ["swiftc", "-parse-as-library", "-module-cache-path", str(directory / "module-cache"),
                 "-F", str(framework_parent), "-framework", "whisper",
                 "-Xlinker", "-rpath", "-Xlinker", str(framework_parent)]
    if reference:
        arguments += ["-D", "REFERENCE_ONLY"]
    else:
        arguments += [str(SUBJECT)]
    arguments += [str(HARNESS), "-o", str(binary)]
    status, _, diagnostics = bounded_run(arguments, directory, timeout=120, memory_mib=2048)
    # Keep the production input opaque even if Swift includes source snippets in diagnostics.
    diagnostic_lines = "\n".join(line for line in diagnostics.splitlines()
                                 if "error:" in line or "warning:" in line)
    test.assertEqual(status, 0, f"Public validator harness compile contract failed:\n{diagnostic_lines}")
    return binary


def copy_prefix(destination, length):
    with MODEL.open("rb") as source, destination.open("wb") as target:
        while length:
            chunk = source.read(min(length, MIB))
            if not chunk:
                raise AssertionError("Requested corruption prefix exceeds trusted fixture")
            target.write(chunk)
            length -= len(chunk)


def tensor_start():
    """Locate weights in the trusted fixture, following pinned whisper.cpp's metadata layout."""
    with MODEL.open("rb") as source:
        source.seek(48)  # GGML magic followed by eleven int32 hyperparameters.
        mel_count, fft_count = struct.unpack("<2i", source.read(8))
        if not (0 < mel_count <= 128 and 0 < fft_count <= 1024):
            raise AssertionError("Trusted fixture has unexpected mel dimensions")
        source.seek(mel_count * fft_count * 4, 1)
        vocabulary_count, = struct.unpack("<i", source.read(4))
        if not 0 < vocabulary_count <= 100_000:
            raise AssertionError("Trusted fixture has unexpected vocabulary size")
        for _ in range(vocabulary_count):
            length, = struct.unpack("<I", source.read(4))
            if length > MIB:
                raise AssertionError("Trusted fixture has unexpected token length")
            source.seek(length, 1)
        return source.tell()


class WhisperModelValidationTests(unittest.TestCase):
    def assert_verdict(self, binary, candidate, expected):
        status, output, diagnostics = bounded_run([str(binary), str(candidate)], candidate.parent)
        self.assertEqual(status, expected,
                         f"{candidate.name}: expected {'valid' if expected == 0 else 'rejection'}, "
                         f"exit={status}, stdout={output!r}, stderr={diagnostics}")
        self.assertEqual(output.strip(), "VALID" if expected == 0 else "INVALID",
                         "Harness must distinguish ordinary rejection from a crash or loader failure")

    def test_cpu_native_reference_loads_the_real_checksum_verified_model(self):
        framework_parent = prerequisites(self)
        with tempfile.TemporaryDirectory(prefix="robey-whisper-reference-") as temporary:
            directory = Path(temporary)
            binary = compile_probe(self, directory, framework_parent, reference=True)
            self.assert_verdict(binary, MODEL, 0)
        print(f"CPU native reference accepted Tiny English: {MODEL_SIZE} bytes, SHA256={MODEL_SHA256}",
              flush=True)

    def test_public_validator_accepts_real_model_and_rejects_corrupt_candidates(self):
        self.assertTrue(SUBJECT.is_file(),
                        "Promised Shared/WhisperModelValidator.swift is missing; "
                        "implement enum WhisperModelValidator { static func validate(at url: URL) throws }")
        framework_parent = prerequisites(self)
        with tempfile.TemporaryDirectory(prefix="robey-whisper-validation-") as temporary:
            directory = Path(temporary)
            binary = compile_probe(self, directory, framework_parent)
            with self.subTest(candidate="real-tiny-english"):
                self.assert_verdict(binary, MODEL, 0)

            def check_bytes(name, content):
                candidate = directory / name
                candidate.write_bytes(content)
                try:
                    with self.subTest(candidate=name):
                        self.assert_verdict(binary, candidate, 1)
                finally:
                    candidate.unlink()

            check_bytes("zero-byte.bin", b"")
            check_bytes("text-response.bin", b"Model not found. Please try again.\n")
            check_bytes("html-response.bin", b"<!doctype html><html><body>503 unavailable</body></html>")
            check_bytes("unknown-format.bin", b"GGUF" + bytes(4092))

            # A correct prefix never establishes that all model weights are present.
            for label, length in (("magic-only", 4), ("header-only", 48),
                                  ("metadata-no-tensors", tensor_start()),
                                  ("first-megabyte", MIB), ("half-file", MODEL_SIZE // 2),
                                  ("missing-final-page", MODEL_SIZE - 4096),
                                  ("missing-final-byte", MODEL_SIZE - 1)):
                candidate = directory / f"{label}.bin"
                copy_prefix(candidate, length)
                try:
                    with self.subTest(candidate=label, bytes=length):
                        self.assert_verdict(binary, candidate, 1)
                finally:
                    candidate.unlink()

            # Mutate complete real files: size and magic-only checks cannot pass these.
            # Offsets are public GGML int32 fields, not production validator internals.
            bad_headers = (
                ("negative-vocabulary", ((4, -1),)),
                ("zero-audio-context", ((8, 0),)),
                ("negative-state-dimensions", ((12, -1), (28, -1))),
                ("zero-attention-heads", ((16, 0),)),
                ("overflowing-audio-layers", ((20, 2**31 - 1),)),
                ("overflowing-text-context", ((24, 2**31 - 1),)),
                ("negative-text-layers", ((36, -1),)),
                ("overflowing-mel-dimensions", ((40, 2**31 - 1), (48, 2**31 - 1))),
                ("unknown-weight-format", ((44, 999),)),
                ("invalid-tensor-dimension-count", ((tensor_start(), 5),)),
                ("overflowing-tensor-name-length", ((tensor_start() + 4, 2**31 - 1),)),
                ("overflowing-tensor-dimension", ((tensor_start() + 12, 2**31 - 1),)),
            )
            for label, changes in bad_headers:
                candidate = directory / f"{label}.bin"
                copy_prefix(candidate, MODEL_SIZE)
                with candidate.open("r+b") as stream:
                    for offset, value in changes:
                        stream.seek(offset)
                        stream.write(struct.pack("<i", value))
                try:
                    with self.subTest(candidate=label):
                        self.assert_verdict(binary, candidate, 1)
                finally:
                    candidate.unlink()


if __name__ == "__main__":
    unittest.main()
