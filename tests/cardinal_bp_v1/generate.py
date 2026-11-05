"""Generate a branch-predictor training and recovery program."""

from pathlib import Path
import sys


HERE = Path(__file__).resolve().parent
sys.dont_write_bytecode = True
sys.path.insert(0, str(HERE.parent / "cardinal_stress"))
import generate as isa


def build() -> None:
    isa.PROGRAM.clear()
    isa.LABELS.clear()
    isa.FIXUPS.clear()
    memory = [0] * 128
    memory[0] = 4
    memory[1] = 1
    memory[2] = 0xA1B2C3D4E5F60718

    isa.load(1, 0)             # Loop count: four iterations.
    isa.load(2, 1)             # Decrement by one.
    isa.load(3, 2)             # Nonzero sentinel for visible stores.
    isa.label("loop")
    isa.branch("bez", 0, "body")   # Same PC, taken four times.
    isa.store(3, 16)               # Must be flushed on every iteration.
    isa.label("body")
    isa.alu("VSUB", 1, 1, 2)
    isa.branch("bnez", 1, "loop")  # Taken three times, then not taken.
    isa.store(1, 17)               # Loop exited with r1 = 0.

    isa.branch("bez", 2, "wrong_bez_target")   # Not taken.
    isa.store(3, 18)
    isa.label("wrong_bez_target")
    isa.branch("bnez", 0, "wrong_bnez_target") # Not taken.
    isa.store(3, 19)
    isa.label("wrong_bnez_target")
    isa.branch("bez", 0, "last_target")        # Taken.
    isa.store(3, 20)                           # Must be flushed.
    isa.label("last_target")
    isa.store(3, 21)
    isa.nop()
    isa.nop()
    isa.nop()
    isa.emit(0, "end")

    for index, target in isa.FIXUPS:
        word, description = isa.PROGRAM[index]
        isa.PROGRAM[index] = (word | (isa.LABELS[target] * 4), description)
    expected, touched = isa.execute(memory.copy())
    assert {16, 20}.isdisjoint(touched)
    assert {17, 18, 19, 21}.issubset(touched)
    assert expected[17] == 0
    assert all(expected[index] == memory[2] for index in (18, 19, 21))

    (HERE / "imem.fill").write_text("".join(
        f"{word:08X}  // {index:3d} (PC {index * 4:3d}): {description}\n"
        for index, (word, description) in enumerate(isa.PROGRAM)), encoding="ascii")
    (HERE / "dmem.fill").write_text("".join(
        f"{value:016X}\n" for value in memory), encoding="ascii")
    (HERE / "expected_dmem.dump").write_text("".join(
        f"Memory location # {index:10d} : {value:016x} \n"
        for index, value in enumerate(expected)), encoding="ascii")
    print(f"Generated {len(isa.PROGRAM)} instructions, {len(touched)} executed stores")


if __name__ == "__main__":
    build()
