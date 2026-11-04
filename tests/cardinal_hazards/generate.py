"""Generate a focused Cardinal pipeline hazard program and expected dump."""

from pathlib import Path
import sys


HERE = Path(__file__).resolve().parent
sys.dont_write_bytecode = True
sys.path.insert(0, str(HERE.parent / "cardinal_stress"))
import generate as isa  # Reuse the instruction encoder and independent ISA model.


def build() -> None:
    isa.PROGRAM.clear()
    isa.LABELS.clear()
    isa.FIXUPS.clear()
    memory = [0] * 128
    memory[:5] = [
        0x0123456789ABCDEF,
        0x80FF7F01FF018000,
        1,
        0,
        0xF0E1D2C3B4A59687,
    ]

    # Immediate LD -> SD register dependency.
    isa.load(1, 0)
    isa.store(1, 16)
    isa.load(2, 1)
    isa.store(2, 17)

    # Immediate SD -> LD of the same address, then LD -> SD again.
    isa.store(1, 18)
    isa.load(3, 18)
    isa.store(3, 19)

    # Consecutive loads, followed by a use of both loaded operands.
    isa.load(4, 0)
    isa.load(5, 1)
    isa.alu("VADD", 6, 4, 5)
    isa.store(6, 20)

    # Consecutive stores, then loads of both stored addresses.
    isa.store(1, 21)
    isa.store(2, 22)
    isa.load(7, 21)
    isa.load(8, 22)
    isa.store(7, 23)
    isa.store(8, 24)

    # An ALU instruction followed by LD; its result must survive the LD.
    isa.alu("VMOV", 9, 1, 0)
    isa.load(10, 0)
    isa.store(9, 25)

    # LD -> ALU on read port 0 and read port 1.
    isa.load(11, 0)
    isa.alu("VADD", 12, 11, 2)
    isa.store(12, 26)
    isa.load(11, 1)
    isa.alu("VADD", 12, 1, 11)
    isa.store(12, 27)

    # Consecutive ALU producers and consumers on each read port.
    isa.alu("VADD", 13, 1, 2)
    isa.alu("VXOR", 14, 13, 1)
    isa.alu("VOR", 15, 1, 14)
    isa.store(15, 28)

    # SD -> ALU has no register dependency, but exercises stage overlap.
    isa.store(1, 29)
    isa.alu("VADD", 16, 1, 2)
    isa.store(16, 30)

    # LD -> partial write -> partial write -> SD on the same register.
    isa.load(17, 4)
    isa.alu("VADD", 17, 1, 2, "b", "e")
    isa.alu("VXOR", 17, 17, 1, "h", "o")
    isa.store(17, 31)

    # WB-to-ID forwarding with a one-instruction gap.
    isa.alu("VMOV", 18, 2, 0)
    isa.nop()
    isa.alu("VADD", 19, 18, 1)
    isa.store(19, 32)

    # ALU -> BEZ taken; the following SD must be flushed.
    isa.alu("VXOR", 20, 1, 1)
    isa.branch("bez", 20, "alu_bez_target")
    isa.store(1, 33)
    isa.label("alu_bez_target")
    isa.store(2, 34)

    # LD -> BNEZ taken, also with a wrong-path SD.
    isa.load(21, 2)
    isa.branch("bnez", 21, "ld_bnez_target")
    isa.store(1, 35)
    isa.label("ld_bnez_target")
    isa.store(2, 36)

    # Both branches not taken; their sequential stores must execute.
    isa.branch("bez", 21, "untaken_bez_target")
    isa.store(1, 37)
    isa.label("untaken_bez_target")
    isa.branch("bnez", 20, "untaken_bnez_target")
    isa.store(1, 38)
    isa.label("untaken_bnez_target")

    # A taken branch flushes another branch in the following IF slot.
    isa.branch("bnez", 21, "branch_target")
    isa.branch("bez", 0, "wrong_branch_target")
    isa.label("branch_target")
    isa.store(2, 39)
    isa.branch("bnez", 21, "after_wrong_branch_target")
    isa.label("wrong_branch_target")
    isa.store(1, 40)
    isa.label("after_wrong_branch_target")

    # A load may target r0, but r0 must remain zero.
    isa.load(0, 1)
    isa.store(0, 41)

    # Two stores to the same address: the second wins, then LD sees it.
    isa.store(1, 42)
    isa.store(2, 42)
    isa.load(22, 42)
    isa.store(22, 43)

    # Two loads or an ALU and a load writing the same register: newer wins.
    isa.load(23, 0)
    isa.load(23, 1)
    isa.store(23, 44)
    isa.alu("VMOV", 24, 1, 0)
    isa.load(24, 1)
    isa.store(24, 45)

    isa.nop()
    isa.nop()
    isa.nop()
    isa.emit(0, "end")

    for index, target in isa.FIXUPS:
        word, description = isa.PROGRAM[index]
        isa.PROGRAM[index] = (word | (isa.LABELS[target] * 4), description)
    assert len(isa.PROGRAM) <= 256

    expected, touched = isa.execute(memory.copy())
    assert {33, 35, 40}.isdisjoint(touched)
    assert set(range(16, 33)).issubset(touched)
    assert {34, 36, 37, 38, 39, 41, 42, 43, 44, 45}.issubset(touched)
    assert expected[16] == memory[0] and expected[19] == memory[0]
    assert expected[22] == memory[1] and expected[24] == memory[1]
    assert expected[41] == 0
    assert all(expected[index] == memory[1] for index in (42, 43, 44, 45))

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
