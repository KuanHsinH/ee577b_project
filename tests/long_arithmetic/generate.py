"""Generate a 16-node Phase 3 regression for the pipelined ALU operations.

The instruction encoder and sequential ISA oracle come from the existing
cardinal_stress generator. Run from any directory with Python 3.
"""

from __future__ import annotations

import importlib.util
from pathlib import Path


HERE = Path(__file__).resolve().parent
ISA_SOURCE = HERE.parent / "cardinal_stress" / "generate.py"
spec = importlib.util.spec_from_file_location("cardinal_stress_isa", ISA_SOURCE)
assert spec is not None and spec.loader is not None
isa = importlib.util.module_from_spec(spec)
spec.loader.exec_module(isa)


def build() -> None:
    isa.PROGRAM.clear()
    isa.LABELS.clear()
    isa.FIXUPS.clear()

    memory = [0] * 128
    memory[0] = 0xF123456789ABCDEF  # large square root and nontrivial lanes
    memory[1] = 0x0305070B0D111317  # multiplier operand
    memory[2] = 0x0001000200030000  # zero and nonzero divisor lanes
    memory[3] = 3                   # nonzero doubleword divisor
    memory[5] = 0x1122334455667788  # partial-write destination seed

    for reg, address in ((1, 0), (2, 1), (3, 2), (4, 3), (21, 5)):
        isa.load(reg, address)

    # Every legal width of every pipelined operation is followed by an
    # immediate consumer. The output address identifies the failing case.
    address = 32
    for name in ("VMULEU", "VMULOU", "VSQEU", "VSQOU"):
        for width in "bhw":
            isa.alu(name, 10, 1, 2, width)
            isa.store(10, address)
            address += 1
    for name in ("VDIV", "VMOD", "VSQRT"):
        for width in "bhwd":
            isa.alu(name, 10, 1, 3, width)
            isa.store(10, address)
            address += 1
    assert address == 56

    # Consecutive long operations test both forwarding ports and result
    # alignment as the CPU releases and re-enters the one-cycle stall.
    isa.alu("VMULEU", 11, 1, 2, "w")
    isa.alu("VDIV", 12, 11, 4, "d")
    isa.alu("VMOD", 13, 12, 4, "d")
    isa.alu("VSQRT", 14, 13, 0, "d")
    for reg, address in ((11, 70), (12, 71), (13, 72), (14, 73)):
        isa.store(reg, address)
    isa.alu("VSQOU", 15, 1, 0, "h")
    isa.alu("VDIV", 16, 4, 15, "d")  # producer is source B
    isa.store(16, 74)

    # A branch must see a freshly produced slow result. Both skipped stores
    # must leave their initially zero memory words unchanged.
    isa.alu("VSQRT", 17, 0, 0, "d")
    isa.branch("bez", 17, "sqrt_zero")
    isa.store(1, 75)
    isa.label("sqrt_zero")
    isa.alu("VMOD", 18, 1, 0, "d")  # divide by zero: remainder is dividend
    isa.branch("bnez", 18, "mod_nonzero")
    isa.store(1, 76)
    isa.label("mod_nonzero")
    isa.store(18, 77)

    isa.alu("VDIV", 19, 1, 0, "d")  # divide by zero: quotient is all ones
    isa.store(19, 78)
    isa.alu("VMOD", 20, 1, 0, "d")
    isa.store(20, 79)

    # Keep unselected destination bytes when a slow result has a PPP mask.
    isa.alu("VMULEU", 21, 1, 2, "b", "e")
    isa.store(21, 80)
    isa.alu("VSQRT", 21, 1, 0, "d", "o")
    isa.store(21, 81)

    for _ in range(3):
        isa.nop()
    isa.emit(0, "end")

    for index, target in isa.FIXUPS:
        word, comment = isa.PROGRAM[index]
        isa.PROGRAM[index] = (word | (isa.LABELS[target] * 4), comment)
    assert len(isa.PROGRAM) <= 256

    expected, touched = isa.execute(memory.copy())
    assert set(range(32, 56)).issubset(touched)
    assert {70, 71, 72, 73, 74, 77, 78, 79, 80, 81}.issubset(touched)
    assert {75, 76}.isdisjoint(touched)
    assert expected[75] == expected[76] == 0
    assert expected[77] == expected[79] == memory[0]
    assert expected[78] == (1 << 64) - 1

    imem = "".join(
        f"{word:08X}  // {index:3d} (PC {index * 4:3d}): {comment}\n"
        for index, (word, comment) in enumerate(isa.PROGRAM)
    )
    dmem = "".join(f"{value:016X}\n" for value in memory)
    dump = "".join(
        f"Memory location # {index:10d} : {value:016x} \n"
        for index, value in enumerate(expected)
    )
    for node in range(16):
        (HERE / f"program.imem.{node}.fill").write_text(imem, encoding="ascii")
        (HERE / f"program.dmem.{node}.fill").write_text(dmem, encoding="ascii")
        (HERE / f"expected_dmem.{node}.dump").write_text(dump, encoding="ascii")
    print(f"Generated {len(isa.PROGRAM)} instructions and {len(touched)} checked stores per node")


if __name__ == "__main__":
    build()
