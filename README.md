# EE577B Project Phase 3: Cardinal NIC and Chip Multiprocessor Framework

This directory is the Phase 3 workspace. It contains the course framework,
the corrected NIC, the base Phase 2 CPU with NIC address handling, and the
Project 1 4x4 mesh connected in `cardinal_cmp`. The one-router+NIC
checkpoint and the course's full multiprocessor program have passed on
NC-Sim. Additional 16-node communication regressions are in `tests/` and
await NC-Sim runs.

The Phase 3 handout describes a 4-node ring. This year's Project 1 was the
4x4 mesh, so Phase 3 uses the mesh: one processor and one NIC at every one
of the sixteen mesh nodes, the Project 1 mesh packet format, and the mesh
VC phase rule. Everything else in the handout (the NIC, the processor
changes, the testbenches, the report) applies unchanged. Where this README
and the handout differ, this README applies.

## Contents

| Path | Description |
|---|---|
| `design/cardinal_cmp.v` | Top-level multiprocessor: sixteen CPUs, sixteen NICs, and the 4x4 mesh. The module name and port list are fixed. |
| `design/cardinal_cpu.v` | Base Phase 2 processor extended with the Phase 3 NIC ports, address decode, and load-data selection. |
| `design/cardinal_nic.v` | NIC implementation. The module name and port list follow the corrected NIC specification. |
| `design/cardinal_node.v` | One router+NIC tile used for module-level bring-up; the processor register interface is exposed for a testbench or CPU connection. |
| `design/gold_mesh_4x4.v` | Project 1 4x4 mesh, with `gold_router.v`, `arbiter.v`, and `buffer.v` in `design/`. |
| `include/imem.v`, `include/dmem.v` | Instruction and data memory models (the same as in Phase 2). Part of the testbench. Do not modify. |
| `tb/tb_cmp.v` | Basic top-level testbench: runs one program set on the sixteen nodes, dumps the sixteen data memories and, for `make test`, compares them with expected dumps. Do not change the `cardinal_cmp` instance. |
| `tb/tb_cardinal_nic.v` | Basic NIC testbench: reset, one send, one receive. A starting point for your own NIC testbench (handout item 3). |
| `tb/tb_cardinal_node.v` | One-tile testbench. It models processor register accesses and a neighboring router to check both packet directions and link backpressure. |
| `cmp_test.asm`, `cmp_test.imem.N.fill`, `cmp_test.dmem.N.fill` | The course CMP test program and its data (see "Sample program"), N = 0..15. |
| `expected_dmem.N.dump` | Expected data memory dumps of the sample program. |
| `makefile`, `cds.lib`, `hdl.var`, `scripts/`, `work/` | NC-Sim flow. |
| `dumps/` | Created by the CMP runs: the data memory dumps. `make clean` keeps this directory, because the dumps are submitted. |
| `waves/` | Created by `make cmpwave` and `make nicwave`: the waveform databases. `make clean` removes this directory. |
| `setup_v1721.csh` | Course tool environment (NC-Sim, Design Compiler, DesignWare). |

## Environment

The flow uses Cadence NC-Sim (`ncvlog`, `ncelab`, `ncsim`). Load the course
environment before running `make`.

From the C shell:

```csh
source setup_v1721.csh
make test
```

From bash:

```bash
csh -f -c 'source setup_v1721.csh; make test'
```

The makefile compiles the DesignWare simulation models listed in
`DW_COMPONENTS` (by default `DW_div DW_sqrt DW02_mult DW01_addsub`) from
`/tools/synopsys/syn/Y-2026.03/dw/sim_ver` on the vlab servers. The Phase 2
rules apply unchanged:

- You do not need an `include` statement. If your processor uses another
  component (for example `DW_div_pipe` or `DW_div_seq`), add it to
  `DW_COMPONENTS`, either at the end of the line or with a new line
  `DW_COMPONENTS += DW_div_pipe`. Do not remove the default entries: the
  pipelined models instantiate the base components. The grading flow reads
  the `DW_COMPONENTS` lines of your submitted makefile.
- Pipelining, forwarding and stalls are your choice. Waiting for a
  multi-cycle divider or stalling on a dependency is fine; Phase 3 does not
  grade cycle counts (each program only has to finish within the 20000
  cycle limit of the testbench, and the longest grading program takes about
  2100 cycles on the reference design).
- Division by zero behaves as `DW_div` in unsigned mode (`tc_mode = 0`):
  all ones for the quotient, the dividend for the remainder.

## Make targets

| Command | Action |
|---|---|
| `make` or `make sim` | Compile, elaborate and run the CMP testbench on `cmp_test.imem.N.fill` and `cmp_test.dmem.N.fill`. Writes `dumps/cmp_test.dmem.N.dump` (N = 0..15). |
| `make test` | `make sim`; the testbench also compares the sixteen data memories with `expected_dmem.N.dump`, lists every location that differs and prints `TEST PASSED` or `TEST FAILED`. MEM[5]-MEM[7] are compared as a set (see below). |
| `make nic` | Compile and run `tb/tb_cardinal_nic.v` on your NIC. |
| `make node` | Compile and run the one-router+NIC tile testbench. |
| `make simg` | CMP simulation in the SimVision GUI. |
| `make nicg` | NIC testbench in the SimVision GUI. |
| `make nodeg` | One-tile testbench in the SimVision GUI. |
| `make cmpwave` | Batch `make test` that also records every signal into `waves/cmp.shm`. |
| `make nicwave` | Batch `make nic` that also records every signal into `waves/nic.shm`. |
| `make clean` | Remove generated files, including `work/` and `waves/`, and keep `dumps/`. Run this before you create your zip file. |

To run another program set:

```bash
make test PREFIX=tests/my_test EXPECTED=tests/my_expected UNORDERED=5:7
```

reads `tests/my_test.imem.N.fill` and `tests/my_test.dmem.N.fill`, writes
`dumps/my_test.dmem.N.dump` and compares with `tests/my_expected.N.dump`.
Use relative paths. In the C shell, a `#` inside a path starts a comment.

## Waveforms for the report

The report shows waveforms of both testbenches. The makefile has four
commands for them:

| Command | What it does |
|---|---|
| `make nicwave` | Runs the NIC testbench in batch and records `waves/nic.shm` |
| `make cmpwave` | Runs `make test` in batch and records `waves/cmp.shm` |
| `make nicg` | Runs the NIC testbench in the SimVision GUI |
| `make simg` | Runs the CMP testbench in the SimVision GUI |

After a batch run, open the database in SimVision:

```bash
simvision waves/nic.shm     # or: simvision waves/cmp.shm
```

With `make nicg` and `make simg`, SimVision opens with every signal being
recorded, and you press Run. SimVision needs a working X display. Every
signal of the hierarchy is recorded, so you only choose what to show.

| Testbench | Where the signals are |
|---|---|
| NIC | `tb_cardinal_nic` holds both sides of the NIC (`clk`, `net_polarity`, `nicEn`, `nicWrEn`, `addr`, `d_in`, `d_out`, `net_si`, `net_ri`, `net_di`, `net_so`, `net_ro`, `net_do`); your internal buffers and status bits are below it, in `tb_cardinal_nic.NIC` |
| System | `tb_cmp.CMP` holds the wires of every node (`nodeN_nicEn`, `nodeN_addr_nic`, `nodeN_din_nic`, `nodeN_dout_nic`, `nodeN_net_so`, `nodeN_net_ro`, `nodeN_net_do`, `nodeN_net_si`, `nodeN_net_di`, `nodeN_polarity`, `nodeN_memWrEn`, `nodeN_addr_out`, `nodeN_d_out`); the modules are below it, in `tb_cmp.CMP.cpuN`, `tb_cmp.CMP.nicN` and `tb_cmp.CMP.mesh` |

The provided `tb/tb_cardinal_nic.v` only covers reset, one send and one
receive. The other cases of the report need your additions to that
testbench. The provided `tb/tb_cmp.v` and the sample program produce the
send and receive waveforms of the system part; the checks listed under
"Sample program" need your own programs and one change to `tb/tb_cmp.v`.

## Fixed interfaces

### cardinal_cmp

The grading testbench instantiates your multiprocessor by port name. Keep
the header of `design/cardinal_cmp.v` exactly as provided: `clk`, `reset`
and, for every node N = 0..15,

```verilog
    input  [0:31] nodeN_inst_in,    // instruction from the instruction memory
    input  [0:63] nodeN_d_in,       // load data from the data memory
    output [0:31] nodeN_pc_out,     // instruction memory address
    output [0:63] nodeN_d_out,      // store data to the data memory
    output [0:31] nodeN_addr_out,   // data memory address
    output        nodeN_memWrEn,    // data memory write enable
    output        nodeN_memEn       // data memory enable
```

- Node N is the processor and the NIC connected to mesh port `nodeN_*`, at
  mesh coordinate (x = N mod 4, y = N / 4): node 0 is the upper-left
  corner, node 3 the upper-right, node 12 the lower-left, node 15 the
  lower-right (Project 1 rules, section 3).
- The module name and the port names (case-sensitive), directions and
  widths must match exactly. If they differ, the elaboration step
  (`ncelab`) stops with an error, for example `*E,CUVMUR` (module not
  found), `*E,CUVPOM` (port name not found) or `*F,CUVMPW` (port width
  differs). The handout penalizes such a design like code that does not
  compile.
- The NIC signals of every node (`nodeN_addr_nic`, `nodeN_din_nic`,
  `nodeN_dout_nic`, `nodeN_nicEn`, `nodeN_nicWrEn`, Figure 1 of the
  handout) are internal wires between the processor and the NIC of a
  node; the testbench instantiates only the ports listed above and leaves
  any extra output port unconnected. You may add them as
  outputs for your own observation, but you do not have to.
- Keep the `gold_mesh_4x4` instance of the template and connect your NICs
  to it as the template shows. Do not add ports for the mesh.
- Do not define modules named `imem`, `dmem`, `tb_cmp` or `tb_cardinal_nic`
  in `design/`.

### gold_mesh_4x4

The mesh is your Project 1 design. `design/gold_mesh_4x4.v` is a
port-only template with the Project 1 interface (`clk`, `reset` and, for
N = 0..15, `nodeN_pesi`, `nodeN_peri`, `nodeN_pedi`, `nodeN_peso`,
`nodeN_pero`, `nodeN_pedo`, `nodeN_polarity`, parameter `PACKET_SIZE`
= 64); its outputs are tied off so that the framework elaborates, but it
delivers nothing. Replace it with your mesh (keep the header) and add all
of your router's submodules to `design/`. Fix the problems the Project 1
grading reported before you integrate it. If your mesh fails in the
system or is missing, the graders run your processors and NICs with a
reference mesh and you receive 70% of the design score obtained that way
(see the submission guide).

### cardinal_nic

The NIC grading testbench instantiates your NIC by port name. Keep the
header of `design/cardinal_nic.v` exactly as provided (the names of the
corrected NIC specification):

```verilog
module cardinal_nic (
    input         clk, reset,
    input  [0:1]  addr,          // register select
    input  [0:63] d_in,          // packet from the processor
    output [0:63] d_out,         // register content to the processor
    input         nicEn, nicWrEn,
    input         net_si,        // router sends a packet
    output        net_ri,        // input channel buffer is empty
    input  [0:63] net_di,        // packet from the router
    output        net_so,        // NIC sends a packet
    input         net_ro,        // router can accept a packet
    output [0:63] net_do,        // packet to the router
    input         net_polarity   // polarity of the connected router
);
```

The write enable is `nicWrEn` (corrected NIC specification, Figure 2 and
Table 1). If your Project 1 NIC uses `nicEnWr`, rename the
port.

### Bit numbering: [0:63] in Phase 3, [63:0] in Project 1

Phase 3 follows the Phase 2 processor convention: every bus is declared
`[0:N-1]`, bit 0 is the MSB. The Project 1 mesh and the Project 1 NIC rules
declared the same buses `[N-1:0]`, bit N-1 the MSB. The bit **positions**
are the same in both notations, only the numbers differ:

| Meaning | Phase 3 / processor `[0:63]` | Project 1 / mesh `[63:0]` |
|---|---|---|
| vc bit (MSB of a packet) | bit 0 | bit 63 |
| destination x, y | bits 2-3, 4-5 | bits 61:60, 59:58 |
| hop field | bits 8-15 | bits 55:48 |
| source, payload | bits 16-31, 32-63 | bits 47:32, 31:0 |
| status bit on `d_out` (LSB) | bit 63 | bit 0 |
| NIC register select `addr`: high bit, low bit | `addr[0]`, `addr[1]` | `addr[1]`, `addr[0]` |

- The NIC and `cardinal_cmp` templates use `[0:63]` and `[0:1]`, and the
  testbenches drive them with `[0:63]` values (`addr = 2'b10` is the output
  buffer in both notations).
- You may keep your Project 1 NIC with its `[63:0]` and `[1:0]` port
  declarations: Verilog connects ports by name and vector bits by
  position, MSB to MSB, so `d_in[63]` is still the vc bit and `addr[1]`
  the high address bit inside such a module (the graders' tools accept
  either declaration, the width must be 64 or 2). What you must not do is
  mix the two: a module declared `[0:63]` must test `d_in[0]` for the vc
  bit and `addr[0]` for the high address bit.
- `cardinal_cmp` connects the NIC's `[0:63]` `net_do`/`net_di` directly to
  your mesh's `[63:0]` `nodeN_pedi`/`nodeN_pedo`, as the template shows. No
  bit reversal is needed anywhere.

### cardinal_cpu

Use the header of `design/cardinal_cpu.v` as provided: the Phase 2 ports
plus `addr_nic[0:1]`, `din_nic[0:63]`, `dout_nic[0:63]`, `nicEn` and
`nicWrEn` (Figure 1 of the handout). The `cardinal_cmp` template connects
these names.

## NIC behaviour

Follow the corrected NIC specification. The grading testbenches assume the
following, which is also how the Project 1 mesh expects its PE port to be
driven (Project 1 rules, section 5).

### Register map and processor side

| `addr` | Register | Access |
|---|---|---|
| `00` | input channel buffer | read only; a load empties the buffer |
| `01` | input channel status | read only (1 = a packet is in the buffer) |
| `10` | output channel buffer | write only |
| `11` | output channel status | read only (1 = a packet waits to be sent) |

- `addr`, `d_in`, `nicEn` and `nicWrEn` are sampled at the rising clock
  edge, like the data memory inputs. A store (`nicEn = nicWrEn = 1`,
  `addr = 10`) is written at that edge. For a load (`nicEn = 1`,
  `nicWrEn = 0`), the selected register appears on `d_out` after that edge,
  during the following cycle. A status read puts the bit on `d_out[63]`,
  the other bits are 0. `d_out` is 0 after an edge at which `nicEn` was 0.
- A store to an occupied output buffer is ignored. Stores to the other
  three registers are ignored. A load from the empty input buffer is
  undefined (the programmer polls the status first).
- Reset is synchronous and active high. After reset both buffers are empty,
  both status registers are 0, `net_so = 0`, `net_ri = 1` and `d_out = 0`.

### Router side

- Input channel: when `net_si = 1` at a rising edge, the packet on `net_di`
  is latched into the input buffer and `net_ri` (= buffer empty) drops. The
  router only sends while `net_ri = 1`. `net_ri` rises again after the
  processor has read the buffer.
- Output channel: the router (and the grading testbench) looks at
  `net_so` and `net_do` only at rising clock edges. A packet is taken at
  an edge where `net_so = 1`; at that edge `net_ro` must be 1 and
  `net_polarity` must be `~vc` (the packet is on the link during the
  `~vc` cycle: a VC1 packet is taken at an edge where the polarity is 0,
  Project 1 rules section 5, and Figure 3 of the NIC specification). After
  that edge the buffer is empty and `net_so` must be 0 at the next edge.
  How you produce `net_so` is up to you: a registered output decided at
  the previous edge (where the sampled polarity equals vc) or a
  combinational one (`net_so = full & net_ro & (net_polarity != vc)`); both
  pass the grading bench.
  **Note:** the Project 1 NIC testbench used the opposite phase (a vc = 0
  packet taken at an edge where the polarity is 0). The mesh ignores the vc
  bit when it selects a buffer, so such a NIC still delivers every packet,
  but the Phase 3 NIC testbench grades the rule above. If your Project 1
  NIC follows the old rule, invert its phase condition.
- Blocking: the router may deassert `net_ro` between the edge at which you
  decide to send and the edge at which it samples `net_so` (its ready
  signal depends on the polarity and belongs to the other VC buffer).
  Release the output buffer only if `net_ro` was 1 at the edge where
  `net_so` was 1; otherwise keep the packet and offer it again two cycles
  later. A NIC that drops the packet in that case loses packets under
  load (the grading programs include such cases).
- The NIC must handle both vc values: it detects the vc bit of each packet
  and waits for the proper polarity. Do not build two NIC types.

## Processor changes (NIC specification, "Interfacing with Processor")

- `addr_out = {16'b0, immediate}`. If `addr_out[16]` and `addr_out[17]` are
  both 1 (`immediate[0:1] == 2'b11`), the load or store accesses the NIC:
  assert `nicEn` (and `nicWrEn` for a store), put `addr_out[30:31]` on
  `addr_nic` and the store data on `din_nic`; keep `memEn` and `memWrEn` at
  0. Any other address is a data memory access as in Phase 2 (the memory
  model uses `addr_out[24:31]`); `nicEn` stays 0.
- A load from the NIC returns the value of `dout_nic`, which is valid in
  the cycle after the edge at which the NIC sampled the request, exactly
  like `d_in` from the data memory. Multiplex the load data between
  `d_in` and `dout_nic` accordingly.
- Everything else of the Phase 2 processor (pipeline, hazards, PPP,
  division by zero, reset) stays as graded in Phase 2. The grading programs
  of Phase 3 include the 39 single-processor programs of the course package
  (`imem_1.fill` to `imem_39.fill`), run on all sixteen nodes.

## Packets and routing

Packet format of the Project 1 mesh, in the processor's bit numbering
(`[0:63]`, bit 0 is the MSB):

| Bits (`[0:63]`) | Field |
|---|---|
| 0 | vc (0 = VC0, 1 = VC1) |
| 1 | reserved (the ring's direction bit), 0 |
| 2-3 | destination x (column, 0..3) |
| 4-5 | destination y (row, 0..3) |
| 6-7 | reserved, 0 |
| 8-15 | hop field: the Manhattan distance H in unary, `(1 << H) - 1` |
| 16-31 | source node number |
| 32-63 | payload |

Your Project 1 mesh code declares the same bus `[63:0]` and calls bit k of
this table bit 63 - k (the vc bit is `pedi[63]` there). The positions are
identical; see "Bit numbering" above.

- The destination node is D = 4y + x. The mesh routes by x first, then y.
  Node N is at x = N mod 4, y = N / 4.
- The hop field is informational: a router may shift it, clear it or leave
  it, so the hop field of a received packet is not compared by the
  testbenches (its nibbles are `xx` in the expected dumps). Reserved bits,
  source and payload must reach the receiver unchanged. The NIC and the
  processor must not alter any field.
- VC rule of the sample program (the handout's rule, extended to the
  mesh): processors in columns 0 and 1 (x = 0, 1) send on odd virtual
  channels (vc = 1), processors in columns 2 and 3 on even ones (vc = 0).
  Your design must work with any vc value in any packet.

The processor sends a packet by polling the output status (`0xC003`) until
it reads 0 and then storing the packet to `0xC002`. It receives by polling
the input status (`0xC001`) until it reads 1 and then loading from `0xC000`.
The polling loops are in the assembly code, not in hardware (NIC
specification). `cmp_test.asm` shows both.

A NIC has one input buffer and one output buffer, so a program that sends
many packets before it receives any can deadlock the network (every node
waits for an output buffer that cannot drain because nobody reads).
Interleave sends and receives, as `cmp_test.asm` and the grading programs
do, or make sure that the receivers read.

## Sample program

`cmp_test.asm` is the course CMP test adapted to the mesh: every processor
sends one packet to its right neighbour (x + 1 mod 4), one to its lower
neighbour (y + 1 mod 4) and one to the opposite node (x + 2, y + 2 mod 4),
and stores the three packets it receives at MEM[5]-MEM[7] in arrival order.
Each pattern is a permutation of the nodes, so every node receives exactly
three packets. The same program runs on every node; the packets to send
are in `cmp_test.dmem.N.fill` (MEM[0]-MEM[2]); the payload is
`0x0000SSDD` (source SS, destination DD).

`make test` compares the dumps with `expected_dmem.N.dump`. Because the
arrival order of the three packets depends on the pipeline timing of your
design and on the mesh, MEM[5]-MEM[7] are compared as a set
(`UNORDERED=5:7` in the makefile): the three expected packets must be
there, in any order. The hop field of a received packet is `xx` in the
expected dump and is not compared. The other locations are compared
exactly; a line whose expected value is all `x` is not compared. The
grading testbench compares received packets the same way.

The sample program is only a start. A design can pass `make test` and
still lose most of the grading programs: for example, the sample program
cannot see a processor that also writes the data memory on NIC stores,
because the stray stores land on words that end up with the same values.
The report (submission guide, item R2) therefore asks for these checks. Put
the program sets in `tests/`, each as `tests/<name>.imem.N.fill`,
`tests/<name>.dmem.N.fill` and `tests/<name>_exp.N.dump`.

| Check | What to verify | How |
|---|---|---|
| (d) Reset | A program set run twice, with a reset and a reload of the memories in between, passes both times | Change `tb/tb_cmp.v` |
| (e) Processor | One of your Part 2 test programs gives the Part 2 results on all sixteen nodes | Program set |
| (f) Communication | Every node exchanges a packet with every other node (all routes, 1 to 6 hops), with sends and receives interleaved; the same with the opposite vc values; two packets to one destination; reserved bits set, arbitrary source and payload values delivered unchanged | Program sets |
| (g) NIC address map | Status registers read 0 after reset; with distinctive values in MEM[0]-MEM[3], a NIC load does not return them and a NIC store does not change them; addresses with bits 16:17 = 01 or 10 reach the data memory; other addresses with bits 16:17 = 11 reach the NIC; stores to read-only registers change nothing | Program set |
| (h) Blocking | Senders burst 10 packets while the receivers are busy in a delay loop, and again with a delay before every receive; no packet is lost or duplicated | Program sets, one waveform |
| (i) Tight loops | Back-to-back load and branch polling with no VNOPs, sends and receives in an irregular order | Program set |

Run one with `make test PREFIX=tests/<name> EXPECTED=tests/<name>_exp
UNORDERED=<lo>:<hi>`, where `<lo>:<hi>` is the range of words holding
received packets.

## Testbench rules

- Memory words that the `.fill` files do not set are 0.
- Reset is held for 5 cycles. The program of a node ends when the node
  fetches the word `00000000`; the testbench then keeps feeding 0 to that
  node (the instruction memory does not wrap around) while the other nodes
  finish. When all sixteen nodes have fetched the end word, the testbench
  waits 5 cycles and dumps MEM[0]-MEM[127] of every node to `dumps/`.
- The clock period is `CYCLE_TIME` = 4 ns (250 MHz), as the handout asks.
- The grading testbench runs many program sets back to back with a reset
  before each one. Reset must therefore clear all state of the processors,
  the NICs and the mesh (Project 1 required the same of the mesh).

## Submission

Follow the Phase 3 submission guide. In short: `make clean`, then zip this
directory with your RTL in `design/`, your testbenches in `tb/`, your
programs (`cmp_test.asm`, the `.fill` files), `dumps/` and the report. Run
`make test` before `make clean`: the clean keeps `dumps/`.
