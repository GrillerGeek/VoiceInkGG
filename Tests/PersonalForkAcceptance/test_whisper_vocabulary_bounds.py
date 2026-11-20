"""Reject a complete GGML model with a vocabulary unsupported by pinned Whisper.

Run: python3 -B -m unittest discover -s Tests/PersonalForkAcceptance -p test_whisper_vocabulary_bounds.py -v

The production validator remains an opaque compiler input. This regression derives
its fixture from the checksum-verified, task-owned Tiny English file and the pinned
GGML tensor format. Only the production validator sees the mutated candidate; the
native reference loader is never called on it. The six prior test files are reused
without modification. Native prerequisite gaps retain the existing explicit skips.
"""

import math
from pathlib import Path
import shutil
import struct
import tempfile
import unittest

import test_whisper_model_validation as validation
from test_whisper_model_validation import (
    MODEL, MODEL_SIZE, SUBJECT,
    compile_probe, prerequisites, tensor_start,
)


def expanded_unsupported_vocabulary(test, candidate):
    """Add three F16 embedding rows while preserving all other trusted model bytes."""
    embedding = None
    with MODEL.open("rb") as source:
        source.seek(tensor_start())
        while source.tell() < MODEL_SIZE:
            record = source.tell()
            descriptor = source.read(12)
            test.assertEqual(len(descriptor), 12, "Trusted tensor descriptor is incomplete")
            dimensions_count, name_length, tensor_type = struct.unpack("<3i", descriptor)
            test.assertIn(dimensions_count, (1, 2, 3), "Unexpected trusted tensor rank")
            test.assertTrue(0 < name_length < 1024, "Unexpected trusted tensor name length")
            test.assertIn(tensor_type, (0, 1), "Tiny fixture must use F32/F16 tensors")
            dimensions = struct.unpack(f"<{dimensions_count}i", source.read(4 * dimensions_count))
            test.assertTrue(all(value > 0 for value in dimensions), "Invalid trusted tensor dimensions")
            name = source.read(name_length)
            test.assertEqual(len(name), name_length, "Trusted tensor name is incomplete")
            payload_start = source.tell()
            payload_end = payload_start + math.prod(dimensions) * (4 if tensor_type == 0 else 2)
            test.assertLessEqual(payload_end, MODEL_SIZE, "Trusted tensor extends beyond fixture")
            if name == b"decoder.token_embedding.weight":
                test.assertIsNone(embedding, "Trusted fixture duplicates token embedding")
                test.assertEqual(dimensions, (384, 51864))
                test.assertEqual(tensor_type, 1, "Expected the task-owned F16 Tiny embedding")
                embedding = (record + 12 + 4, payload_end)
            source.seek(payload_end)
        test.assertEqual(source.tell(), MODEL_SIZE, "Trusted tensor records must consume the file")

    test.assertIsNotNone(embedding, "Trusted Tiny fixture is missing its token embedding")
    vocabulary_dimension_offset, insertion_offset = embedding
    extra_rows = bytes(3 * 384 * 2)
    with MODEL.open("rb") as source, candidate.open("wb") as target:
        remaining = insertion_offset
        while remaining:
            chunk = source.read(min(remaining, 1024 * 1024))
            test.assertTrue(chunk, "Trusted fixture unexpectedly ended during copy")
            target.write(chunk)
            remaining -= len(chunk)
        target.write(extra_rows)
        shutil.copyfileobj(source, target, length=1024 * 1024)
    with candidate.open("r+b") as stream:
        for offset in (4, vocabulary_dimension_offset):
            stream.seek(offset)
            stream.write(struct.pack("<i", 51867))
    test.assertEqual(candidate.stat().st_size, MODEL_SIZE + len(extra_rows))


class WhisperVocabularyBoundsTests(unittest.TestCase):
    def test_complete_consistent_model_rejects_unsupported_51867_vocabulary(self):
        self.assertTrue(SUBJECT.is_file(), "Public WhisperModelValidator source is required")
        framework_parent = prerequisites(self)
        with tempfile.TemporaryDirectory(prefix="robey-whisper-vocabulary-") as temporary:
            directory = Path(temporary)
            binary = compile_probe(self, directory, framework_parent)
            candidate = directory / "complete-unsupported-vocabulary-51867.bin"
            expanded_unsupported_vocabulary(self, candidate)
            # Reuse the bounded 30-second / 768-MiB production API verdict helper.
            validation.WhisperModelValidationTests.assert_verdict(self, binary, candidate, 1)


if __name__ == "__main__":
    unittest.main()
