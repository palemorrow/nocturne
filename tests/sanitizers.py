import os
import shlex
import subprocess
from pathlib import Path

root = Path(__file__).resolve().parent.parent
output = root / "build/sanitizers"
output.mkdir(parents=True, exist_ok=True)
cases = {
    "fault": ["core/fault.c"],
    "policy": ["core/policy.c", "core/routing.c"],
    "transitions": ["core/policy.c"],
    "trace": ["core/trace.c"],
    "abi": ["core/abi.c"],
    "descriptor": ["core/descriptor.c"],
}
environment = dict(os.environ, ASAN_OPTIONS="detect_leaks=0:abort_on_error=1",
                   UBSAN_OPTIONS="halt_on_error=1:print_stacktrace=1")
for name, sources in cases.items():
    executable = output / name
    subprocess.run(shlex.split(os.environ.get("HOSTCC", "cc")) + ["-std=c11", "-g",
                   "-O1", "-Wall", "-Wextra", "-Werror", "-Iinclude",
                   "-fsanitize=address,undefined", "-fno-omit-frame-pointer",
                   f"tests/{name}.c", *sources, "-o", str(executable)], cwd=root, check=True)
    subprocess.run([executable], env=environment, check=True, stdout=subprocess.DEVNULL)
    print(f"{name}: address and undefined-behavior sanitizers passed")
