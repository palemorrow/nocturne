import hashlib
import shutil
import subprocess
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parent.parent
hashes = []
with tempfile.TemporaryDirectory(prefix="nocturne-reproduce-") as temporary:
    for name in ("first", "second"):
        target = Path(temporary) / name
        target.mkdir()
        for directory in ("arch", "core", "guest", "include", "tools"):
            shutil.copytree(root / directory, target / directory)
        shutil.copy(root / "Makefile", target / "Makefile")
        subprocess.run(["make", "--no-print-directory", "-j2", "all"], cwd=target,
                       check=True, stdout=subprocess.DEVNULL)
        hashes.append(hashlib.sha256((target / "build/nocturne.elf").read_bytes()).hexdigest())
assert hashes[0] == hashes[1], hashes
print("independent build directories produce identical elf bytes", hashes[0])
