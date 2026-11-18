# Pipelined arithmetic regression

This 16-node Phase 3 program checks all legal widths of `VMULEU`, `VMULOU`,
`VSQEU`, `VSQOU`, `VDIV`, `VMOD`, and `VSQRT`. Every result is stored by the
next instruction. It also checks consecutive long operations with dependent
operands, branches using fresh results, division by zero, and partial writes.
Each node runs the same program and has its own expected memory dump.

From the project root on the course machine, run:

```sh
source setup_v1721.csh
make test PREFIX=tests/long_arithmetic/program EXPECTED=tests/long_arithmetic/expected_dmem UNORDERED=
```

The testbench compares all 128 data-memory locations at each of 16 nodes.
Locations 32-43 identify multiply and square cases; 44-55 identify divide,
modulo, and square-root cases; 70-81 check dependencies and corner cases.
Locations 75 and 76 must stay zero because the preceding branch skips them.

Regenerate the input and expected files with
`python3 tests/long_arithmetic/generate.py`. The expected results come from
the existing sequential ISA model in `tests/cardinal_stress/generate.py`.
This is an RTL functional test; the 4 ns timing target still requires a
synthesis timing report.
