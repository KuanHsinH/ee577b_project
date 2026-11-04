# Cardinal CPU stress program

This directory contains a second `imem.fill`, `dmem.fill`, and
`expected_dmem.dump` for the Phase 2 testbench. It leaves the supplied example
untouched.

## Coverage

- All 18 ALU functions at every legal operand width: 68 function/width cases.
  `VMULEU`, `VMULOU`, `VSQEU`, and `VSQOU` use b/h/w; the others use b/h/w/d.
- Every ALU result is stored by the next instruction at memory addresses
  32–99, testing ALU-to-store forwarding.
- Load-to-ALU dependencies on both read ports, ALU-to-ALU dependencies on both
  read ports, a one-instruction-gap dependency, and two nearby writers to the
  same register (addresses 100–101, 108–109, 122–123).
- All five PPP masks, including partial writes followed by reads of the merged
  destination value (addresses 102–107). These masks must select bytes
  independently of operand width.
- A write to register 0, an illegal ALU function, store then load of the same
  location, and an immediate use of the loaded value (addresses 110–113).
- BEZ and BNEZ taken and not taken, including branches whose conditions come
  from the immediately preceding ALU operation or load. Addresses 114, 117,
  and 120 must remain zero because their stores are on flushed paths; 115,
  116, 118, 119, and 121 must be written.
- VNOP and the zero end-of-program word.

The source data include mixed byte values, high sign bits, zero divisor lanes,
and shift counts. The expected dump covers all 128 locations printed by the
provided testbench.

## Run

Place this directory under the Phase 2 simulation directory, then from that
directory run:

```sh
make test IMEM=tests/cardinal_stress/imem.fill DMEM=tests/cardinal_stress/dmem.fill EXPECTED=tests/cardinal_stress/expected_dmem.dump
```

To regenerate the files, run `python tests/cardinal_stress/generate.py` from
any directory. The generator decodes and executes the emitted instruction
words in a sequential ISA model to calculate the expected memory. That model
also reproduced all 128 words of the supplied example's expected dump.
