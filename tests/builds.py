import argparse
import shutil
import subprocess
from pathlib import Path

root = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser()
parser.add_argument("--compiler", choices=("gcc", "clang"))
arguments = parser.parse_args()
compilers = {"gcc": "aarch64-linux-gnu-gcc", "clang": "clang --target=aarch64-linux-gnu"}
for name in ([arguments.compiler] if arguments.compiler else compilers):
    target = root / "build/compilers" / name
    if target.exists():
        shutil.rmtree(target)
    target.mkdir(parents=True)
    for directory in ("arch", "core", "guest", "include", "tools", "tests"):
        shutil.copytree(root / directory, target / directory,
                        ignore=shutil.ignore_patterns("__pycache__"))
    shutil.copy(root / "Makefile", target / "Makefile")
    log = root / "build" / f"compiler-{name}.log"
    with log.open("w") as output:
        result = subprocess.run(["make", "-j2", f"CC={compilers[name]}", "test-image", "test-qemu"],
                                cwd=target, stdout=output, stderr=subprocess.STDOUT)
    if result.returncode:
        raise SystemExit(log.read_text())
    print(f"{name}: image layout and every qemu fixture passed")
