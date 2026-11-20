#!/usr/bin/env python3
"""Offline, exact-revision notice collection. Run after dependency resolution.

Copies tracked LICENSE/COPYING/NOTICE files from exact matching checkouts;
missing or wrong-revision checkouts remain explicitly pending. No network use.
"""
import hashlib
import json
from pathlib import Path
import re
import subprocess
import shutil

ROOT = Path(__file__).resolve().parent.parent
LEGAL = ROOT / "VoiceInk/Resources/Legal"
RESOLVED = ROOT / "VoiceInk.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
CHECKOUTS = ROOT / ".local-dependencies/SourcePackages/checkouts"


def git(directory, *args):
    return subprocess.check_output(["git", "-C", str(directory), *args], text=True).strip()


def collect(identity, location, revision, checkout):
    record = dict(identity=identity, source=location, revision=revision, status="PENDING: checkout unavailable", files=[])
    if not checkout or not (checkout / ".git").exists():
        return record
    actual = git(checkout, "rev-parse", "HEAD")
    if actual != revision:
        record["status"] = "PENDING: checkout revision differs (" + actual + ")"
        return record
    if git(checkout, "status", "--porcelain", "--untracked-files=no"):
        record["status"] = "PENDING: tracked checkout modifications"
        return record
    names = git(checkout, "ls-files").splitlines()
    for name in names:
        if not re.fullmatch(r"(?:LICEN[CS]E|COPYING|NOTICE|COPYRIGHT)(?:[._-].*)?", Path(name).name, flags=re.I):
            continue
        source = checkout / name
        if not source.is_file() or source.is_symlink():
            continue
        content = source.read_bytes()
        destination = LEGAL / "Dependencies" / identity / name
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(content)
        record["files"].append(dict(path=destination.relative_to(LEGAL).as_posix(), source_path=name,
                                    sha256=hashlib.sha256(content).hexdigest()))
    record["status"] = "Verified exact checkout; retained license/notice files" if record["files"] else "PENDING: no tracked license/notice file found"
    return record


def main():
    checkouts = {p.name.lower(): p for p in CHECKOUTS.iterdir()} if CHECKOUTS.exists() else {}
    records = []
    for pin in json.loads(RESOLVED.read_text())["pins"]:
        records.append(collect(pin["identity"], pin["location"], pin["state"]["revision"], checkouts.get(pin["identity"].lower())))
    current = {pin["identity"] for pin in json.loads(RESOLVED.read_text())["pins"]} | {"whisper.cpp"}
    dependencies = LEGAL / "Dependencies"
    if dependencies.is_dir():
        for directory in dependencies.iterdir():
            if directory.is_dir() and directory.name not in current:
                shutil.rmtree(directory)
    records.append(collect("whisper.cpp", "https://github.com/ggml-org/whisper.cpp", "2eeeba56e9edd762b4b38467bab96c2517163158", ROOT / ".local-dependencies/whisper.cpp"))
    (LEGAL / "DEPENDENCY_INVENTORY.json").write_text(json.dumps(records, indent=2) + "\n")
    text = ["# Dependency license inventory", "", "Generated offline from Package.resolved and available exact-revision checkouts. Pending means no license text has yet been verified for that resolved revision. This is an inventory, not a complete distribution clearance. Re-run `python3 branding/CollectDependencyNotices.py` after resolving the final package graph.", ""]
    for record in records:
        text += ["## " + record["identity"], "", "Source: " + record["source"], "", "Revision: `" + record["revision"] + "`", "", "Status: " + record["status"], ""]
        for file in record["files"]:
            text += ["- [" + file["source_path"] + "](" + file["path"] + "), SHA-256 `" + file["sha256"] + "`."]
        text += [""]
    (LEGAL / "DEPENDENCY_INVENTORY.md").write_text("\n".join(text))
    print(f"Inventory: {len(records)} entries; {sum(r['status'].startswith('Verified') for r in records)} exact checkouts verified; {sum(r['status'].startswith('PENDING') for r in records)} pending.")


if __name__ == "__main__":
    main()
