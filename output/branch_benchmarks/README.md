# Two additional Cardinal CPU branch workloads

These are **new files**; the original CPU, BPB, testbench, and earlier tests
were not changed. Each case has an assembly listing (`program.asm`),
instruction memory (`imem.fill`), initial data memory (`dmem.fill`), and the
expected full data-memory dump (`expected_dmem.dump`). They use the CPU-only
Phase 2 memory format.

## What each case tests

| Case | Purpose | Branch behavior | Expected data-memory results |
|---|---|---|---|
| `mixed_workload` | A broader comparison with arithmetic, a repeated store, two conditions, and a loop | One condition is taken 1/2 the time, one 1/4 the time, and the loop-back branch is taken 95/96 times | 16=96, 17=48, 18=72, 19–21=0, 22=4656, 24=144, 25=96 |
| `alternating_adversarial` | A counterexample for the two-bit BPB | Three branch sites each alternate taken, not taken, beginning with taken; a loop-back branch repeats the sequence | 16=96, 17–19=48, 20=1, 21=0 |

The mixed case is less focused on one predictor pattern than `hot_taken`,
`alternating`, or `nested`, but it is still a small synthetic benchmark. Report
results for several programs rather than treating one as a universal workload.

## Why prediction can lose

The supplied BPB initializes every two-bit counter to `01`. For a branch whose
outcomes repeat **taken, not taken**, the counter repeats `01 → 10 → 01`.
It predicts the wrong direction on both outcomes. A CPU that always fetches
`PC + 4` (static not taken) gets the not-taken outcomes right. The adversarial
case repeats this at three separate branch PCs, enough to outweigh the BPB's
gain on the loop-back branch.

An independent sequential trace of the generated instruction words gives
these *source-level estimates*:

| Case | Program instructions | Resolved branches | Static-not-taken misses | Two-bit BPB misses |
|---|---:|---:|---:|---:|
| `mixed_workload` | 1287 | 288 | 167 | 74 |
| `alternating_adversarial` | 828 | 384 | 239 | 290 |

These are not RTL simulation measurements. Use the metrics testbenches on your
CPU implementations to obtain the numbers for your presentation. A run is
usable only when its memory comparison passes. In this four-stage CPU, each
wrong prediction normally causes one IF/ID flush and one lost cycle; the exact
simulation counts can also reflect pipeline timing and implementation details.

## Run

Put these folders under `tests/branch_benchmarks/` in the Phase 2 simulation
project. Use one case at a time with the CPU-only metrics benches. For example:

```sh
make -B test TOP=tb_cardinal_cpu_metrics \
  TB_FILE=./tb/tb_cardinal_cpu_metrics.v \
  IMEM=tests/branch_benchmarks/mixed_workload/imem.fill \
  DMEM=tests/branch_benchmarks/mixed_workload/dmem.fill \
  EXPECTED=tests/branch_benchmarks/mixed_workload/expected_dmem.dump \
  DUMP=mixed_baseline.dump

make -B test TOP=tb_cardinal_cpu_bp_metrics \
  TB_FILE=./tb/tb_cardinal_cpu_bp_metrics.v \
  IMEM=tests/branch_benchmarks/mixed_workload/imem.fill \
  DMEM=tests/branch_benchmarks/mixed_workload/dmem.fill \
  EXPECTED=tests/branch_benchmarks/mixed_workload/expected_dmem.dump \
  DUMP=mixed_bp.dump
```

Replace `mixed_workload` in the three input paths with
`alternating_adversarial` for the counterexample. Keep the same IMEM, DMEM,
and expected dump for both CPU versions.
