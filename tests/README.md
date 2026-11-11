# 16-node CMP communication regressions

`generate_cmp_tests.py` generated the instruction, data, and expected-dump
files in this directory. Its instruction encoders are checked against the
course `cmp_test.imem.0.fill` encodings before generation.

Run these from the Phase 3 project root after `source setup_v1721.csh`:

```csh
make test PREFIX=tests/all_to_all_base EXPECTED=tests/all_to_all_base_exp UNORDERED=16:30
make test PREFIX=tests/all_to_all_flipped EXPECTED=tests/all_to_all_flipped_exp UNORDERED=16:30
make test PREFIX=tests/gather_15 EXPECTED=tests/gather_15_exp UNORDERED=16:30
```

Run `gather_15` first for the shortest targeted check, then the two
all-to-all variants. Each successful command must print `All nodes completed`
and `TEST PASSED: all 2048 memory locations match ...`. A `WARNING: not every
node fetched the end-of-program word` means the run has not completed, even
if a later memory comparison happens to pass. The DesignWare division models
may print warnings while inactive; inspect the `TEST PASSED`/`TEST FAILED`
lines separately.

- **all_to_all_base:** Each node sends one packet to every other node in
  fifteen phases, for 240 packets. A node sends one, receives one, then
  advances. Columns 0-1 use VC1; columns 2-3 use VC0.
- **all_to_all_flipped:** The same 240 transfers with every VC bit inverted.
- **gather_15:** The other fifteen nodes send concurrently to node 15. Node
  15 polls and stores all fifteen arrivals. This creates PE and link
  contention near the lower-right corner.

Packet payloads distinguish source, destination, and phase. The reserved
header bits vary, and the expected dumps compare them. Expected received
values use `xx` only for the hop byte because the mesh may shift it. Received
packets are compared as a set at MEM[16]-MEM[30], since their arrival order
depends on contention. The `.asm` files list the binary words with matching
assembly mnemonics.

These are communication regressions. The Phase 3 submission guide also
calls for a repeated-reset run, CPU instruction regressions, address-map
corner cases, and controlled blocking cases.
