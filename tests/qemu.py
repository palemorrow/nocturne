import importlib.util
import subprocess
from pathlib import Path

root = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location("run", root / "tools/run.py")
run = importlib.util.module_from_spec(spec)
spec.loader.exec_module(run)
traces = root / "build/traces"
traces.mkdir(parents=True, exist_ok=True)
for case in run.CASES:
    result = subprocess.run(run.command(case), capture_output=True, text=True, timeout=15)
    output = result.stdout + result.stderr
    (traces / f"{case}.txt").write_text(output)
    assert result.returncode == 0 and output.endswith("result pass\n"), (case, output)
    assert "failure " not in output, (case, output)
    if case in ("s2-write", "s1-off", "guest-remap", "tlb-revoke"):
        assert output.count("backing unchanged") == (2 if case == "guest-remap" else 1)
        assert "far-valid=1" in output and " ipa=0x0000000040300000" in output
    if case == "tlb-revoke":
        assert "permission revoked" in output and "resume retry" in output
    if case == "timer":
        assert "irq physical-timer guest-i=1 target=el2" in output
    print(f"{case}: pass")
print(f"{len(run.CASES)} qemu experiments passed")
