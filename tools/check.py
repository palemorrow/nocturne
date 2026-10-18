import re
from pathlib import Path

root = Path(__file__).resolve().parent.parent
modules = set()
for source in (root / "proof/Nocturne").glob("*.agda"):
    text = source.read_text()
    assert "--safe" in text and "--without-K" in text, source
    assert not re.search(r"\bpostulate\b|\{!!?|!\}|NON_TERMINATING|TERMINATING|allow-unsolved|type-in-type|no-positivity|no-termination", text), source
    if source.stem != "Everything":
        modules.add("Nocturne." + source.stem)
aggregate = (root / "proof/Nocturne/Everything.agda").read_text()
assert modules <= set(re.findall(r"import (Nocturne\.\w+)", aggregate))
for directory in ("arch", "core", "guest", "include", "tests", "tools"):
    for source in (root / directory).rglob("*"):
        if source.suffix in (".c", ".h", ".S"):
            assert not re.search(r"//|/\*|\*/", source.read_text()), source
assert not (root / "docs").exists() and not (root / "design.txt").exists()
print(f"{len(modules)} safe proof modules covered; no authored holes, postulates, or code comments")
