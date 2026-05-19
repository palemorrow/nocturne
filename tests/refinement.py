import subprocess
from pathlib import Path

root = Path(__file__).resolve().parent.parent
oracle = subprocess.check_output([root / "build/oracle/Oracle"], text=True)
concrete = subprocess.check_output([root / "build/policy-host"], text=True)
expected = oracle.splitlines()
actual = concrete.splitlines()
assert len(expected) == len(actual) == 240
for number, (model, implementation) in enumerate(zip(expected, actual), 1):
    assert model == implementation, (number, model, implementation)
print("240 exhaustive policy transitions agree with the compiled agda model")
