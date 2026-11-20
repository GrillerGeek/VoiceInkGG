#!/usr/bin/env python3
"""Require the reviewed lock's exact, unmodified source checkouts."""
import json
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[1]
pins = json.loads((root / 'VoiceInk.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved').read_text())['pins']
checkouts = {p.name.lower(): p for p in (root / '.local-dependencies/SourcePackages/checkouts').iterdir()}
for pin in pins:
    checkout = checkouts.get(pin['identity'].lower())
    if checkout is None:
        raise SystemExit(f"Missing checkout: {pin['identity']}; resolve locked packages first")
    actual = subprocess.check_output(['git', '-C', str(checkout), 'rev-parse', 'HEAD'], text=True).strip()
    dirty = subprocess.check_output(['git', '-C', str(checkout), 'status', '--porcelain', '--untracked-files=no'], text=True).strip()
    if actual != pin['state']['revision'] or dirty:
        raise SystemExit(f"Unreviewed revision or tracked modifications: {pin['identity']}")
print(f'Verified {len(pins)} exact, clean Swift package checkouts')
