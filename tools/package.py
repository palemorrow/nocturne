import gzip
import hashlib
import io
import json
import os
import subprocess
import tarfile
from pathlib import Path

root = Path(__file__).resolve().parent.parent
output = root / "build/dist"
output.mkdir(parents=True, exist_ok=True)
revision = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip()
epoch = int(os.environ.get("SOURCE_DATE_EPOCH") or subprocess.check_output(
    ["git", "log", "-1", "--format=%ct"], cwd=root, text=True).strip())
files = {}
for directory in ("arch", "core", "guest", "include", "proof", "tests", "tools"):
    for source in sorted((root / directory).rglob("*")):
        if source.suffix in (".c", ".h", ".S", ".ld", ".agda", ".py", ".sh"):
            files[source.relative_to(root).as_posix()] = source.read_bytes()
for name in ("README.txt", "Makefile", "nocturne.agda-lib", "build/nocturne.elf", "build/nocturne.map"):
    files[name] = (root / name).read_bytes()
for trace in sorted((root / "build/traces").glob("*.txt")):
    files[trace.relative_to(root).as_posix()] = trace.read_bytes()
files["build/toolchain.txt"] = subprocess.check_output(["make", "--no-print-directory", "doctor"], cwd=root)
manifest = {"revision": revision, "source_date_epoch": epoch,
            "sha256": {name: hashlib.sha256(data).hexdigest() for name, data in sorted(files.items())}}
files["manifest.json"] = (json.dumps(manifest, indent=2, sort_keys=True) + "\n").encode()
archive = output / "nocturne.tar.gz"
with archive.open("wb") as destination:
    with gzip.GzipFile(filename="", fileobj=destination, mode="wb", mtime=0) as compressed:
        with tarfile.open(fileobj=compressed, mode="w") as tar:
            for name, data in sorted(files.items()):
                entry = tarfile.TarInfo("nocturne/" + name)
                entry.size = len(data)
                entry.mtime = epoch
                entry.mode = 0o644
                tar.addfile(entry, io.BytesIO(data))
digest = hashlib.sha256(archive.read_bytes()).hexdigest()
(output / "SHA256SUMS").write_text(f"{digest}  {archive.name}\n")
print(archive.relative_to(root), digest)
