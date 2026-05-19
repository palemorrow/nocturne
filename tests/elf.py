import struct
from pathlib import Path

image = Path("build/nocturne.elf").read_bytes()
assert image[:7] == b"\x7fELF\x02\x01\x01"
header = struct.unpack_from("<HHIQQQIHHHHHH", image, 16)
kind, machine, version, entry, phoff = header[:5]
assert (kind, machine, version) == (2, 183, 1)
assert entry == 0x40100000
assert header[8] == 56 and header[9] == 4
previous_end = 0
for index in range(header[9]):
    segment = struct.unpack_from("<IIQQQQQQ", image, phoff + index * 56)
    kind, flags, offset, va, pa, filesz, memsz, alignment = segment
    assert kind == 1 and flags in (5, 6)
    assert va == pa and filesz <= memsz
    assert 0x40100000 <= pa and pa + memsz <= 0x40400000
    assert pa >= previous_end
    assert offset + filesz <= len(image) and pa % alignment == offset % alignment
    previous_end = pa + memsz
assert b"/home/" not in image
print("elf entry, segment ownership, permissions, and debug paths checked")
