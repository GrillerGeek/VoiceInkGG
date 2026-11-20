#!/usr/bin/env python3
"""Archive current source, including uncommitted changes, excluding ignored/private files."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tarfile

root = Path(__file__).resolve().parents[1]
output = Path(sys.argv[1]).resolve()
if not output.is_relative_to(root / '.review-build'):
    raise SystemExit('Source archives must remain in ignored .review-build/')
names = subprocess.check_output(['git', 'ls-files', '-z', '--cached', '--others', '--exclude-standard'], cwd=root).decode().split('\0')
tracked = set(subprocess.check_output(['git', 'ls-files', '-z'], cwd=root).decode().split('\0'))
# New source is restricted to the explicitly reviewed implementation/legal/docs
# surfaces. The existing tracked application sound cues and Silero VAD resource
# are known upstream assets; downloaded transcription weights are excluded.
def reviewed_new_source(name):
    path = Path(name)
    if name == 'THIRD_PARTY_NOTICES.md':
        return True
    if name.startswith('VoiceInk/Resources/Legal/'):
        return path.suffix in {'', '.md', '.txt'} or name == 'VoiceInk/Resources/Legal/DEPENDENCY_INVENTORY.json'
    rules = {
        'Shared/': {'.swift'}, 'VoiceInk/': {'.swift'},
        'Tests/PersonalForkAcceptance/': {'.swift', '.py'},
        'scripts/': {'.sh', '.py'}, 'branding/': {'.swift', '.py', '.md', '.svg'},
        'docs/': {'.md'},
    }
    return any(name.startswith(prefix) and path.suffix in extensions for prefix, extensions in rules.items())

files = []
for name in sorted(set(names)):
    if not name:
        continue
    path = root / name
    if not path.is_file():
        continue
    if any(part in {'.git', '.local-dependencies', '.review-build', '.local-build', 'node_modules', '__pycache__'} for part in Path(name).parts):
        continue
    if name.endswith(('progress.json', 'progress.json.lock')):
        continue  # Execution bookkeeping is represented by the reviewed plan.
    if name not in tracked and not reviewed_new_source(name):
        raise SystemExit(f'Unreviewed untracked file in source list: {name}')
    # Never follow an outside symlink into this source artifact.
    if path.is_symlink() or not path.resolve().is_relative_to(root):
        raise SystemExit(f'Unexpected source symlink: {name}')
    known_asset = name.startswith('VoiceInk/Resources/Sounds/') and name in tracked
    known_asset |= name == 'VoiceInk/Resources/models/ggml-silero-v5.1.2.bin' and name in tracked
    if path.name.startswith('.env') or path.suffix.lower() in {'.p12', '.p8', '.key', '.mobileprovision', '.log', '.aiff', '.gguf'} or (path.suffix.lower() in {'.wav', '.mp3', '.bin'} and not known_asset):
        raise SystemExit(f'Unexpected credential/audio/model candidate in source list: {name}')
    files.append({'path': name, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
manifest = {
    'base_commit': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip(),
    'source_state': 'working-tree snapshot including listed uncommitted and untracked source',
    'whisper_cpp_revision': '2eeeba56e9edd762b4b38467bab96c2517163158',
    'refine_helper': 'excluded: model license does not authorize this fork',
    'files': files,
}
if len(sys.argv) > 2:
    binding = json.loads(Path(sys.argv[2]).read_text())
    manifest['build_binding'] = {key: binding[key] for key in ('source_input_digest', 'app_tree_digest', 'base_commit', 'whisper_cpp_revision')}
output.mkdir(parents=True, exist_ok=True)
manifest_path = output / 'source-provenance.json'
manifest_path.write_text(json.dumps(manifest, indent=2) + '\n')
with tarfile.open(output / 'Robey-Voice-0.1.0-source.tar.gz', 'w:gz') as archive:
    for item in files:
        archive.add(root / item['path'], arcname='RobeyVoice-Source/' + item['path'], recursive=False)
    archive.add(manifest_path, arcname='RobeyVoice-Source/source-provenance.json')
print(f'Archived {len(files)} source files with SHA-256 provenance')
