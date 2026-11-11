#!/usr/bin/env python3
"""Generate Phase 3 CMP communication programs and expected memory dumps.

The generated instruction files use the same encodings as cmp_test.imem.N.fill.
Run this from any directory; outputs are placed next to this script.
"""
from pathlib import Path

OUT = Path(__file__).resolve().parent
NODES = 16
RECEIVE_FIRST = 16
RECEIVE_LAST = 30


def vld(register, address):
    return 0x80000000 | (register << 21) | address


def vsd(register, address):
    return 0x84000000 | (register << 21) | address


def vbez(register, target):
    return 0x88000000 | (register << 21) | target


def vbnez(register, target):
    return 0x8C000000 | (register << 21) | target


def packet(source, destination, phase, flipped=False, marker=0xA5):
    sx, sy = source % 4, source // 4
    dx, dy = destination % 4, destination // 4
    distance = abs(dx - sx) + abs(dy - sy)
    vc = int(sx < 2) ^ int(flipped)
    reserved_1 = (source + phase) & 1
    reserved_2 = (source ^ phase) & 3
    payload = (marker << 24) | (phase << 16) | (source << 8) | destination
    return (
        (vc << 63)
        | (reserved_1 << 62)
        | (dx << 60)
        | (dy << 58)
        | (reserved_2 << 56)
        | (((1 << distance) - 1) << 48)
        | (source << 32)
        | payload
    )


def receive_expectation(value):
    hex_word = f"{value:016x}"
    return hex_word[:2] + "xx" + hex_word[4:]


def write_program(prefix, node, instructions):
    path = OUT / f"{prefix}.imem.{node}.fill"
    lines = [
        f"{word:08X}  // PC {index * 4:3d}: {description}"
        for index, (word, description) in enumerate(instructions)
    ]
    path.write_text("\n".join(lines) + "\n", encoding="ascii")


def write_data_and_expected(prefix, node, initial, received):
    dmem = [0] * 128
    expected = ["0000000000000000"] * 128
    for address, value in initial.items():
        dmem[address] = value
        expected[address] = f"{value:016x}"
    for address, value in received.items():
        expected[address] = receive_expectation(value)

    dmem_path = OUT / f"{prefix}.dmem.{node}.fill"
    last_initial_address = max(initial, default=0)
    dmem_path.write_text(
        "\n".join(f"{dmem[address]:016X}" for address in range(last_initial_address + 1))
        + "\n",
        encoding="ascii",
    )

    expected_path = OUT / f"{prefix}_exp.{node}.dump"
    expected_path.write_text(
        "\n".join(
            f"Memory location # {address:10d} : {expected[address]}"
            for address in range(128)
        )
        + "\n",
        encoding="ascii",
    )


def all_to_all_program():
    result = [(0xF0000000, "vnop")]
    for phase in range(1, NODES):
        result.append((vld(10, phase - 1), f"phase {phase}: vld r10, {phase - 1}"))
        tx_target = len(result) * 4
        result.append((vld(1, 0xC003), f"tx{phase}: vld r1, 0xC003"))
        result.append((vbnez(1, tx_target), f"vbnez r1, tx{phase}"))
        result.append((vsd(10, 0xC002), "vsd r10, 0xC002"))
        rx_target = len(result) * 4
        result.append((vld(2, 0xC001), f"rx{phase}: vld r2, 0xC001"))
        result.append((vbez(2, rx_target), f"vbez r2, rx{phase}"))
        result.append((vld(5, 0xC000), "vld r5, 0xC000"))
        result.append((vsd(5, RECEIVE_FIRST + phase - 1),
                       f"vsd r5, {RECEIVE_FIRST + phase - 1}"))
    result.append((0, "end"))
    assert len(result) < 256
    return result


def gather_sender_program():
    return [
        (0xF0000000, "vnop"),
        (vld(10, 0), "vld r10, 0"),
        (vld(1, 0xC003), "tx: vld r1, 0xC003"),
        (vbnez(1, 8), "vbnez r1, tx"),
        (vsd(10, 0xC002), "vsd r10, 0xC002"),
        (0, "end"),
    ]


def gather_receiver_program():
    result = [(0xF0000000, "vnop")]
    for item in range(NODES - 1):
        target = len(result) * 4
        result.append((vld(2, 0xC001), f"rx{item}: vld r2, 0xC001"))
        result.append((vbez(2, target), f"vbez r2, rx{item}"))
        result.append((vld(5, 0xC000), "vld r5, 0xC000"))
        result.append((vsd(5, RECEIVE_FIRST + item),
                       f"vsd r5, {RECEIVE_FIRST + item}"))
    result.append((0, "end"))
    return result


def write_asm(name, instructions):
    (OUT / name).write_text(
        "\n".join(
            f"{index * 4:3d}: {word:08X}  {description}"
            for index, (word, description) in enumerate(instructions)
        )
        + "\n",
        encoding="ascii",
    )


def generate_all_to_all(prefix, flipped, marker):
    instructions = all_to_all_program()
    for node in range(NODES):
        initial = {
            phase - 1: packet(node, (node + phase) % NODES,
                              phase, flipped, marker)
            for phase in range(1, NODES)
        }
        received = {
            RECEIVE_FIRST + phase - 1:
                packet((node - phase) % NODES, node, phase, flipped, marker)
            for phase in range(1, NODES)
        }
        write_program(prefix, node, instructions)
        write_data_and_expected(prefix, node, initial, received)


def generate_gather():
    prefix = "gather_15"
    destination = 15
    sender_instructions = gather_sender_program()
    receiver_instructions = gather_receiver_program()
    for node in range(NODES):
        if node == destination:
            received = {
                RECEIVE_FIRST + source:
                    packet(source, destination, 1, marker=0xC3)
                for source in range(destination)
            }
            write_program(prefix, node, receiver_instructions)
            write_data_and_expected(prefix, node, {}, received)
        else:
            value = packet(node, destination, 1, marker=0xC3)
            write_program(prefix, node, sender_instructions)
            write_data_and_expected(prefix, node, {0: value}, {})


def main():
    assert vld(10, 0) == 0x81400000
    assert vld(1, 0xC003) == 0x8020C003
    assert vbnez(1, 16) == 0x8C200010
    assert vsd(10, 0xC002) == 0x8540C002
    assert vbez(2, 52) == 0x88400034
    generate_all_to_all("all_to_all_base", flipped=False, marker=0xA5)
    generate_all_to_all("all_to_all_flipped", flipped=True, marker=0x5A)
    generate_gather()
    write_asm("all_to_all.asm", all_to_all_program())
    write_asm("gather_sender.asm", gather_sender_program())
    write_asm("gather_receiver.asm", gather_receiver_program())
    print("Generated two 240-packet all-to-all sets and one 15-packet gather set.")


if __name__ == "__main__":
    main()
