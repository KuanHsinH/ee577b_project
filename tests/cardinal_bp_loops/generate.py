"""Generate three long-running branch-predictor regression programs."""

from pathlib import Path
import sys


HERE = Path(__file__).resolve().parent
sys.dont_write_bytecode = True
sys.path.insert(0, str(HERE.parent / "cardinal_stress"))
import generate as isa


def start() -> None:
    isa.PROGRAM.clear()
    isa.LABELS.clear()
    isa.FIXUPS.clear()


def finish(name: str, memory: list[int], checks: dict[int, int]) -> None:
    isa.nop()
    isa.nop()
    isa.nop()
    isa.emit(0, "end")
    for index, target in isa.FIXUPS:
        word, description = isa.PROGRAM[index]
        isa.PROGRAM[index] = (word | isa.LABELS[target] * 4, description)
    assert len(isa.PROGRAM) <= 256
    expected, _ = isa.execute(memory.copy(), max_steps=4000)
    for address, value in checks.items():
        assert expected[address] == value, (name, address, expected[address], value)

    folder = HERE / name
    folder.mkdir(exist_ok=True)
    (folder / "imem.fill").write_text("".join(
        f"{word:08X}  // {index:3d} (PC {index * 4:3d}): {description}\n"
        for index, (word, description) in enumerate(isa.PROGRAM)), encoding="ascii")
    (folder / "dmem.fill").write_text("".join(
        f"{value:016X}\n" for value in memory), encoding="ascii")
    (folder / "expected_dmem.dump").write_text("".join(
        f"Memory location # {index:10d} : {value:016x} \n"
        for index, value in enumerate(expected)), encoding="ascii")
    print(f"{name}: {len(isa.PROGRAM)} instruction words")


def hot_taken() -> None:
    start()
    memory = [0] * 128
    memory[0], memory[1] = 240, 1
    isa.load(1, 0)                 # Remaining iterations.
    isa.load(2, 1)                 # Constant one.
    isa.label("loop")
    isa.branch("bez", 0, "body") # Taken on all 240 iterations.
    isa.store(2, 16)              # Wrong path; must never write.
    isa.label("body")
    isa.alu("VADD", 3, 3, 2)     # Count completed iterations.
    isa.alu("VSUB", 1, 1, 2)
    isa.branch("bnez", 1, "loop") # Taken 239 times, then not taken.
    isa.store(3, 17)
    isa.store(1, 18)
    finish("hot_taken", memory, {16: 0, 17: 240, 18: 0})


def alternating() -> None:
    start()
    memory = [0] * 128
    memory[0], memory[1] = 256, 1
    isa.load(1, 0)
    isa.load(2, 1)
    isa.label("loop")
    isa.alu("VXOR", 3, 3, 2)    # Toggle between 0 and 1.
    isa.branch("bez", 3, "skip_add") # Alternates not taken/taken.
    isa.alu("VADD", 4, 4, 2)
    isa.label("skip_add")
    isa.alu("VSUB", 1, 1, 2)
    isa.branch("bnez", 1, "loop") # Taken 255 times, then not taken.
    isa.store(4, 16)
    isa.store(1, 17)
    isa.store(3, 18)
    finish("alternating", memory, {16: 128, 17: 0, 18: 0})


def nested() -> None:
    start()
    memory = [0] * 128
    memory[0], memory[1], memory[2] = 16, 32, 1
    isa.load(1, 0)                # Outer count.
    isa.load(2, 1)                # Inner count to reload.
    isa.load(3, 2)                # Constant one.
    isa.label("outer")
    isa.alu("VMOV", 5, 2, 0)    # Restart inner loop at 32.
    isa.label("inner")
    isa.alu("VADD", 4, 4, 3)
    isa.alu("VSUB", 5, 5, 3)
    isa.branch("bnez", 5, "inner") # 31 taken + 1 not, per outer loop.
    isa.alu("VSUB", 1, 1, 3)
    isa.branch("bnez", 1, "outer") # 15 taken, then not taken.
    isa.store(4, 16)
    isa.store(1, 17)
    isa.store(5, 18)
    finish("nested", memory, {16: 512, 17: 0, 18: 0})


if __name__ == "__main__":
    hot_taken()
    alternating()
    nested()
