import hashlib
import json
import subprocess
import tarfile
from pathlib import Path

root = Path(__file__).resolve().parent.parent
archive = root / "build/dist/nocturne.tar.gz"
with tarfile.open(archive, "r:gz") as tar:
    names = tar.getnames()
    assert len(names) == len(set(names))
    assert all(name.startswith("nocturne/") and ".." not in Path(name).parts for name in names)
    assert not any("/.deps/" in name or "/_build/" in name for name in names)
    manifest = json.load(tar.extractfile("nocturne/manifest.json"))
    for name, expected in manifest["sha256"].items():
        assert hashlib.sha256(tar.extractfile("nocturne/" + name).read()).hexdigest() == expected, name
    assert tar.extractfile("nocturne/README.txt").read() == (root / "README.txt").read_bytes()
    assert manifest["revision"] == subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip()
    assert len([name for name in names if name.startswith("nocturne/build/traces/")]) >= 23
before = hashlib.sha256(archive.read_bytes()).hexdigest()
subprocess.run(["python3", "tools/package.py"], cwd=root, check=True, stdout=subprocess.DEVNULL)
assert hashlib.sha256(archive.read_bytes()).hexdigest() == before
print("artifact hashes, revision, traces, readme preservation, and deterministic archive checked")
