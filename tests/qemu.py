import importlib.util
import subprocess
import re
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
    if case in run.NEGATIVE:
        assert result.returncode == 1 and output.endswith("result fail\n"), (case, output)
        assert "failure " + run.NEGATIVE[case] in output, (case, output)
    else:
        assert result.returncode == 0 and output.endswith("result pass\n"), (case, output)
        assert "failure " not in output, (case, output)
    sequences = [int(number, 16) for number in re.findall(r"event seq=(0x[0-9a-f]+)", output)]
    assert sequences == list(range(len(sequences))), (case, sequences)
    if case == "trace-full":
        assert len(sequences) == 64
    if case in ("s2-write", "s1-off", "guest-remap", "tlb-revoke"):
        assert output.count("backing unchanged") == (2 if case == "guest-remap" else 1)
        assert "far-valid=1" in output and " ipa=0x0000000040300000" in output
    if case in ("s2-write", "s2-execute", "guest-remap", "tlb-revoke", "l2-block"):
        assert "translation at=software" in output
    if case == "s1-deny":
        assert "guest stage1 write denied at el1" in output
        assert " far=" not in output
    if case == "tlb-revoke":
        assert "permission revoked" in output and "resume retry" in output
    if case == "timer":
        assert "irq physical-timer guest-i=1 target=el2" in output
        assert "kind=irq esr-valid=0 esr=0x0000000000000000" in output
    print(f"{case}: pass")
print(f"{len(run.CASES)} qemu experiments passed")
