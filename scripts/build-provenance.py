#!/usr/bin/env python3
"""Bind a built application to the exact source/resource inputs used by its build."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def digest_tree(base, files):
    records = []
    for path in sorted(files):
        if path.is_symlink():
            value = 'symlink:' + str(path.readlink())
        elif path.is_file():
            value = hashlib.sha256(path.read_bytes()).hexdigest()
        else:
            continue
        records.append({'path': path.relative_to(base).as_posix(), 'sha256_or_link': value})
    return hashlib.sha256(json.dumps(records, sort_keys=True).encode()).hexdigest(), records


def source_inputs():
    files = []
    for directory in ('VoiceInk', 'Shared', 'VoiceInk.xcodeproj'):
        files.extend(p for p in (ROOT / directory).rglob('*') if p.is_file() and 'xcuserdata' not in p.parts and p.name != '.DS_Store')
    files += [ROOT / name for name in ('Makefile', 'LocalBuild.xcconfig', 'scripts/build-local.sh', 'scripts/build-whisper.sh', 'scripts/resolve-packages.sh', 'scripts/verify-app.sh', 'scripts/build-provenance.py', 'scripts/validate-dependencies.py')]
    return digest_tree(ROOT, files)


def app_digest(app):
    return digest_tree(app, app.rglob('*'))[0]


if __name__ == '__main__':
    action, record_name = sys.argv[1:3]
    record_path = Path(record_name).resolve()
    if not record_path.is_relative_to(ROOT / '.review-build'):
        raise SystemExit('Build records must remain in ignored .review-build/')
    digest, inputs = source_inputs()
    if action == 'begin':
        record_path.parent.mkdir(parents=True, exist_ok=True)
        record_path.write_text(json.dumps({'source_input_digest': digest, 'inputs': inputs}, indent=2) + '\n')
    else:
        record = json.loads(record_path.read_text())
        if record['source_input_digest'] != digest:
            raise SystemExit('Source/resource build inputs changed; rebuild before packaging')
        app = Path(sys.argv[3]).resolve()
        actual_app_digest = app_digest(app)
        if action == 'finish':
            record.update(app_path=str(app), app_tree_digest=actual_app_digest,
                          base_commit=subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
                          whisper_cpp_revision='2eeeba56e9edd762b4b38467bab96c2517163158')
            record_path.write_text(json.dumps(record, indent=2) + '\n')
        elif action == 'verify':
            if record.get('app_path') != str(app) or record.get('app_tree_digest') != actual_app_digest:
                raise SystemExit('Application differs from the recorded build artifact')
        else:
            raise SystemExit('Unknown provenance action')
        print(f'{action}: bound source {digest} and app {actual_app_digest}')
