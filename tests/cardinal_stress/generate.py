"""Generate a Cardinal Phase 2 instruction and memory regression program.

The expected dump is computed by decoding the emitted instruction words and
executing them in a small, sequential ISA model. Run: python generate.py
"""

from __future__ import annotations

from math import isqrt
from pathlib import Path


HERE = Path(__file__).resolve().parent
MASK64 = (1 << 64) - 1
OP = {
    "VAND": 1, "VOR": 2, "VXOR": 3, "VNOT": 4, "VMOV": 5,
    "VADD": 6, "VSUB": 7, "VMULEU": 8, "VMULOU": 9,
    "VSLL": 10, "VSRL": 11, "VSRA": 12, "VRTTH": 13,
    "VDIV": 14, "VMOD": 15, "VSQEU": 16, "VSQOU": 17, "VSQRT": 18,
}
PPP = {"a": 0, "u": 1, "d": 2, "e": 3, "o": 4}
WIDTH = {"b": 0, "h": 1, "w": 2, "d": 3}
PROGRAM: list[tuple[int, str]] = []
LABELS: dict[str, int] = {}
FIXUPS: list[tuple[int, str]] = []


def emit(word: int, description: str) -> None:
    PROGRAM.append((word, description))


def alu(name: str, rd: int, ra: int, rb: int, width: str = "d", ppp: str = "a") -> None:
    word = (0b101010 << 26) | (rd << 21) | (ra << 16) | (rb << 11)
    word |= (PPP[ppp] << 8) | (WIDTH[width] << 6) | OP[name]
    emit(word, f"{name.lower()}.{ppp}{width} r{rd}, r{ra}, r{rb}")


def load(rd: int, addr: int) -> None:
    emit((0b100000 << 26) | (rd << 21) | addr, f"vld r{rd}, {addr}")


def store(rd: int, addr: int) -> None:
    emit((0b100001 << 26) | (rd << 21) | addr, f"vsd r{rd}, {addr}")


def nop() -> None:
    emit(0xF0000000, "vnop")


def label(name: str) -> None:
    assert name not in LABELS
    LABELS[name] = len(PROGRAM)


def branch(name: str, rd: int, target: str) -> None:
    assert name in ("bez", "bnez")
    opcode = 0b100010 if name == "bez" else 0b100011
    FIXUPS.append((len(PROGRAM), target))
    emit((opcode << 26) | (rd << 21), f"v{name} r{rd}, {target}")


def lanes(value: int, bits: int) -> list[int]:
    mask = (1 << bits) - 1
    return [(value >> shift) & mask for shift in range(64 - bits, -1, -bits)]


def join_lanes(values: list[int], bits: int) -> int:
    result = 0
    for value in values:
        result = (result << bits) | (value & ((1 << bits) - 1))
    return result


def eval_alu(code: int, width_code: int, a: int, b: int) -> int:
    bits = 8 << width_code
    av, bv = lanes(a, bits), lanes(b, bits)
    mask = (1 << bits) - 1
    if code == OP["VAND"]:
        return a & b
    if code == OP["VOR"]:
        return a | b
    if code == OP["VXOR"]:
        return a ^ b
    if code == OP["VNOT"]:
        return (~a) & MASK64
    if code == OP["VMOV"]:
        return a
    if code == OP["VADD"]:
        return join_lanes([x + y for x, y in zip(av, bv)], bits)
    if code == OP["VSUB"]:
        return join_lanes([x - y for x, y in zip(av, bv)], bits)
    if code in (OP["VMULEU"], OP["VMULOU"], OP["VSQEU"], OP["VSQOU"]):
        assert width_code < 3
        even = code in (OP["VMULEU"], OP["VSQEU"])
        positions = range(0 if even else 1, len(av), 2)
        products = [av[i] * (av[i] if code in (OP["VSQEU"], OP["VSQOU"]) else bv[i])
                    for i in positions]
        return join_lanes(products, bits * 2)
    if code == OP["VSLL"]:
        return join_lanes([x << (y & (bits - 1)) for x, y in zip(av, bv)], bits)
    if code == OP["VSRL"]:
        return join_lanes([x >> (y & (bits - 1)) for x, y in zip(av, bv)], bits)
    if code == OP["VSRA"]:
        signed = [x - (1 << bits) if x & (1 << (bits - 1)) else x for x in av]
        return join_lanes([x >> (y & (bits - 1)) for x, y in zip(signed, bv)], bits)
    if code == OP["VRTTH"]:
        half = bits // 2
        return join_lanes([((x << half) | (x >> half)) & mask for x in av], bits)
    if code == OP["VDIV"]:
        return join_lanes([x // y if y else mask for x, y in zip(av, bv)], bits)
    if code == OP["VMOD"]:
        return join_lanes([x % y if y else x for x, y in zip(av, bv)], bits)
    if code == OP["VSQRT"]:
        return join_lanes([isqrt(x) for x in av], bits)
    raise ValueError(f"unknown ALU function {code}")


def byte_mask(ppp: int) -> int:
    selected = {
        0: range(8), 1: range(4), 2: range(4, 8),
        3: range(0, 8, 2), 4: range(1, 8, 2),
    }[ppp]
    return sum(0xFF << (8 * (7 - i)) for i in selected)


def execute(memory: list[int]) -> tuple[list[int], set[int]]:
    regs = [0] * 32
    touched: set[int] = set()
    pc = 0
    steps = 0
    while True:
        assert 0 <= pc < len(PROGRAM) and steps < 1000, "program did not terminate"
        word = PROGRAM[pc][0]
        if word == 0:
            break
        opcode = word >> 26
        rd = (word >> 21) & 31
        ra = (word >> 16) & 31
        rb = (word >> 11) & 31
        next_pc = pc + 1
        if opcode == 0b100000:
            regs[rd] = memory[word & 255] if rd else 0
        elif opcode == 0b100001:
            memory[word & 255] = regs[rd]
            touched.add(word & 255)
        elif opcode == 0b100010 and regs[rd] == 0:
            next_pc = (word & 0xFFFF) // 4
        elif opcode == 0b100011 and regs[rd] != 0:
            next_pc = (word & 0xFFFF) // 4
        elif opcode == 0b101010:
            ppp, ww, func = (word >> 8) & 7, (word >> 6) & 3, word & 63
            if func in OP.values() and ppp in range(5) and rd:
                result = eval_alu(func, ww, regs[ra], regs[rb])
                mask = byte_mask(ppp)
                regs[rd] = (regs[rd] & ~mask) | (result & mask)
        pc = next_pc
        steps += 1
    return memory, touched


def build() -> None:
    # Distinct lane values, signed shift cases, zero divisor lanes, zero/one,
    # and shift counts of one at every lane width.
    memory = [0] * 128
    memory[:8] = [
        0x0123456789ABCDEF, 0x80FF7F01FF018000,
        0x0102030405060708, 0x0000000300000000,
        0xF0E1D2C3B4A59687, 0, 1, 0x0101010101010101,
    ]

    for reg, addr in ((1, 0), (2, 1), (3, 2), (4, 3), (5, 5), (6, 6), (7, 7)):
        load(reg, addr)

    # Each legal function/width combination is followed immediately by a
    # dependent store. The store addresses identify the exact failing case.
    destination = 32
    for name in OP:
        widths = "bhw" if name in ("VMULEU", "VMULOU", "VSQEU", "VSQOU") else "bhwd"
        for width in widths:
            alu(name, 10, 1, 2, width)
            store(10, destination)
            destination += 1
    assert destination == 100

    # Nearby EX/WB sources, both input ports, same-register overwrite priority.
    load(20, 4)
    alu("VADD", 31, 1, 20)
    store(31, 123)
    load(20, 4)
    alu("VADD", 21, 20, 1)
    alu("VXOR", 22, 1, 21)
    store(22, 122)
    store(21, 100)
    alu("VXOR", 22, 21, 2)
    store(22, 101)

    # PPP masks are byte based at all widths; read back a partially updated rD.
    load(23, 4)
    alu("VADD", 23, 1, 2, "b", "e")
    store(23, 102)
    alu("VXOR", 23, 23, 1, "h", "o")
    store(23, 103)
    for ppp, width, address in (("u", "w", 104), ("d", "d", 105),
                                ("e", "w", 106), ("o", "d", 107)):
        alu("VADD", 23, 23, 2, width, ppp)
        store(23, address)

    # One instruction gap tests WB-to-ID; back-to-back writers test priority.
    alu("VMOV", 24, 1, 2)
    nop()
    alu("VADD", 25, 24, 2)
    store(25, 108)
    alu("VMOV", 26, 1, 2)
    alu("VMOV", 26, 2, 1)
    alu("VADD", 27, 26, 1)
    store(27, 109)

    alu("VMOV", 0, 1, 2)
    alu("VADD", 28, 0, 6)
    store(28, 110)
    emit((0b101010 << 26) | (28 << 21) | 63, "illegal ALU function (must not write r28)")
    store(28, 111)

    # Store/load of the same location, followed by an immediate consumer.
    store(1, 112)
    load(29, 112)
    alu("VADD", 30, 29, 6)
    store(30, 113)

    # Taken branches must squash the following store; untaken branches must
    # execute it. Both branch types and ALU/load-produced conditions are used.
    alu("VXOR", 11, 1, 1)
    branch("bez", 11, "bez_taken")
    store(1, 114)
    label("bez_taken")
    store(2, 115)
    branch("bez", 6, "bez_not_taken")
    store(1, 116)
    label("bez_not_taken")
    branch("bnez", 6, "bnez_taken")
    store(1, 117)
    label("bnez_taken")
    store(2, 118)
    branch("bnez", 11, "bnez_not_taken")
    store(1, 119)
    label("bnez_not_taken")
    load(12, 5)
    branch("bez", 12, "load_branch_taken")
    store(1, 120)
    label("load_branch_taken")
    store(2, 121)
    nop()
    nop()
    nop()
    emit(0, "end")

    for index, target in FIXUPS:
        word, description = PROGRAM[index]
        PROGRAM[index] = (word | (LABELS[target] * 4), description)
    assert len(PROGRAM) <= 256
    assert max(LABELS.values()) * 4 < 65536

    expected, touched = execute(memory.copy())
    assert {114, 117, 120}.isdisjoint(touched)
    assert {115, 116, 118, 119, 121}.issubset(touched)
    assert set(range(32, 114)).issubset(touched)
    assert {122, 123}.issubset(touched)

    (HERE / "imem.fill").write_text("".join(
        f"{word:08X}  // {index:3d} (PC {index * 4:3d}): {comment}\n"
        for index, (word, comment) in enumerate(PROGRAM)), encoding="ascii")
    (HERE / "dmem.fill").write_text("".join(
        f"{value:016X}\n" for value in memory), encoding="ascii")
    (HERE / "expected_dmem.dump").write_text("".join(
        f"Memory location # {index:10d} : {value:016x} \n"
        for index, value in enumerate(expected)), encoding="ascii")
    print(f"Generated {len(PROGRAM)} instructions, {len(touched)} executed stores")


if __name__ == "__main__":
    build()
