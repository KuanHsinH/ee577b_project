# Cardinal pipeline hazard program

This focused program supplements `tests/cardinal_stress`. It has 74
instructions and an expected dump for all 128 data-memory locations. Each
interesting result has its own output address.

| Instruction sequence | Check address |
|---|---:|
| LD → SD, same register | 16, 17 |
| SD → LD, same address, then LD → SD | 18, 19 |
| LD → LD, then ALU uses both loads | 20 |
| SD → SD, then load both stored locations | 21–24 |
| ALU → LD stage overlap | 25 |
| LD → ALU, read port 0 and read port 1 | 26, 27 |
| ALU → ALU on both read ports, then ALU → SD | 28 |
| SD → ALU stage overlap | 29, 30 |
| LD → two partial ALU writes to the same register → SD | 31 |
| ALU → one instruction gap → ALU | 32 |
| ALU → taken BEZ, flush next SD | 33 remains zero; 34 written |
| LD → taken BNEZ, flush next SD | 35 remains zero; 36 written |
| BEZ and BNEZ not taken | 37, 38 written |
| Taken branch flushes a second branch | 39 written; 40 remains zero |
| LD to register zero | 41 remains zero |
| SD → SD to same address, then LD | 42, 43 |
| LD → LD to same register | 44 |
| ALU → LD to same register | 45 |

Because the CPU is in order and LD/SD addresses are immediate values, some
pairs have no true register dependency. They still check that adjacent memory
operations and stage overlap do not lose or repeat an instruction.

From the Phase 2 simulation directory, with this directory copied under
`tests/`, run:

```sh
make test IMEM=tests/cardinal_hazards/imem.fill DMEM=tests/cardinal_hazards/dmem.fill EXPECTED=tests/cardinal_hazards/expected_dmem.dump
```

Run `python -B tests/cardinal_hazards/generate.py` to regenerate the three
files. The script decodes and executes the emitted instruction words using the
same ISA model as the broader stress program. This checks expected outcomes;
it does not simulate the RTL.
