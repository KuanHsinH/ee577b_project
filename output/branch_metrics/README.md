# Cardinal CPU branch metrics testbenches

These are new, CPU-only testbenches. They do not change either supplied CPU,
the existing `tb_cardinal_cpu.v`, or the memory models.

| File | CPU under test | Meaning of a misprediction |
|---|---|---|
| `tb_cardinal_cpu_metrics.v` | `cardinal_cpu` | A taken branch, because this CPU always fetches `PC + 4` (static not taken) |
| `tb_cardinal_cpu_bp_metrics.v` | `cardinal_cpu_bp_v1` | `mispredict_ID` reports that the BPB prediction was wrong |

Each bench prints, separately for every reset/run:

- Cycles until the zero end-of-program word is fetched.
- Cycles including the original bench's five-cycle pipeline drain.
- Completed instructions and resolved branches.
- Mispredictions and IF/ID flush events.
- Branch accuracy = `(branches - mispredictions) / branches * 100%`.
- CPI = `cycles including drain / completed instructions`.

`Completed instructions` counts actual program instructions entering ID, including
programmed `VNOP`s. A shadow valid bit excludes the bubble `VNOP`s inserted by
flushes. The in-order pipeline and five-cycle drain allow all counted
instructions to finish before reporting. Each wrong prediction causes one
IF/ID flush in these CPU versions, so the misprediction and flush counts should
be equal. If a run fails its memory check, do not use its performance numbers
as a valid comparison.

## Run with the Phase 2 Makefile

Place the two new `.v` files in the Phase 2 project's `tb/` directory, then
run from the project root on the course machine after loading its Cadence
environment. The commands below select the new bench without editing the
Makefile or overwriting the original testbench. `-B` forces the Makefile to
recompile and elaborate when switching between benches.

```sh
make -B test TOP=tb_cardinal_cpu_metrics \
  TB_FILE=./tb/tb_cardinal_cpu_metrics.v \
  IMEM=tests/cardinal_bp_loops/hot_taken/imem.fill \
  DMEM=tests/cardinal_bp_loops/hot_taken/dmem.fill \
  EXPECTED=tests/cardinal_bp_loops/hot_taken/expected_dmem.dump \
  DUMP=baseline_hot_taken.dump

make -B test TOP=tb_cardinal_cpu_bp_metrics \
  TB_FILE=./tb/tb_cardinal_cpu_bp_metrics.v \
  IMEM=tests/cardinal_bp_loops/hot_taken/imem.fill \
  DMEM=tests/cardinal_bp_loops/hot_taken/dmem.fill \
  EXPECTED=tests/cardinal_bp_loops/hot_taken/expected_dmem.dump \
  DUMP=bp_hot_taken.dump

make -B test TOP=tb_cardinal_cpu_metrics \
  TB_FILE=./tb/tb_cardinal_cpu_metrics.v \
  IMEM=tests/cardinal_bp_loops/alternating_adversarial/imem.fill \
  DMEM=tests/cardinal_bp_loops/alternating_adversarial/dmem.fill \
  EXPECTED=tests/cardinal_bp_loops/alternating_adversarial/expected_dmem.dump \
  DUMP=baseline_alternating_adversarial.dump

make -B test TOP=tb_cardinal_cpu_bp_metrics \
  TB_FILE=./tb/tb_cardinal_cpu_bp_metrics.v \
  IMEM=tests/cardinal_bp_loops/alternating_adversarial/imem.fill \
  DMEM=tests/cardinal_bp_loops/alternating_adversarial/dmem.fill \
  EXPECTED=tests/cardinal_bp_loops/alternating_adversarial/expected_dmem.dump \
  DUMP=bp_alternating_adversarial.dump

make -B test TOP=tb_cardinal_cpu_metrics \
  TB_FILE=./tb/tb_cardinal_cpu_metrics.v \
  IMEM=tests/cardinal_bp_loops/nested/imem.fill \
  DMEM=tests/cardinal_bp_loops/nested/dmem.fill \
  EXPECTED=tests/cardinal_bp_loops/nested/expected_dmem.dump \
  DUMP=baseline_nested.dump

make -B test TOP=tb_cardinal_cpu_bp_metrics \
  TB_FILE=./tb/tb_cardinal_cpu_bp_metrics.v \
  IMEM=tests/cardinal_bp_loops/nested/imem.fill \
  DMEM=tests/cardinal_bp_loops/nested/dmem.fill \
  EXPECTED=tests/cardinal_bp_loops/nested/expected_dmem.dump \
  DUMP=bp_nested.dump

make -B test TOP=tb_cardinal_cpu_metrics \
  TB_FILE=./tb/tb_cardinal_cpu_metrics.v \
  IMEM=tests/cardinal_bp_loops/mixed_workload/imem.fill \
  DMEM=tests/cardinal_bp_loops/mixed_workload/dmem.fill \
  EXPECTED=tests/cardinal_bp_loops/mixed_workload/expected_dmem.dump \
  DUMP=baseline_mixed_workload.dump

make -B test TOP=tb_cardinal_cpu_bp_metrics \
  TB_FILE=./tb/tb_cardinal_cpu_bp_metrics.v \
  IMEM=tests/cardinal_bp_loops/mixed_workload/imem.fill \
  DMEM=tests/cardinal_bp_loops/mixed_workload/dmem.fill \
  EXPECTED=tests/cardinal_bp_loops/mixed_workload/expected_dmem.dump \
  DUMP=bp_mixed_workload.dump
```

Replace `hot_taken` with `alternating` or `nested` in all three input paths to
compare the other patterns. The tests run twice by default when `EXPECTED` is
provided; compare Run 1 of each CPU, and check that Run 2 repeats the result.

As a source-level sanity check, the three supplied programs execute the
following numbers of real instructions and branches. These are branch-outcome
counts from the program logic, not measured simulator results:

| Program | Instructions | Branches | Baseline taken branches / expected flushes | BPB expected misses / flushes |
|---|---:|---:|---:|---:|
| `hot_taken` | 967 | 480 | 479 | 3 |
| `alternating` | 1160 | 512 | 383 | 130 |
| `nested` | 1593 | 528 | 511 | 19 |

The BP testbench expects the supplied `cardinal_cpu_bp_v1.v` and `BPB.v` in
`design/`. Use the supplied `cardinal_cpu.v` for the baseline comparison. The
CPU files attached to this request were not modified.

## Scope of the numbers

These benches report simulation-cycle metrics. They do not measure clock
period, area, power, or energy. The original testbench's cycle count to the
end marker and its five-cycle drain are both shown so the CPI convention is
explicit. Accuracy is undefined when a program executes no branches; CPI is
undefined when it executes no instructions.
