# Synthesize both Phase 2 Cardinal CPUs

This package adds a separate synthesis makefile and a Design Compiler script.
It leaves the course makefile and CPU RTL unchanged. The two top modules are
**synthesized separately** under identical library and timing constraints:

- `cardinal_cpu` — baseline CPU
- `cardinal_cpu_bp_v1` — CPU with the 256-entry, two-bit BPB

## Install in the Phase 2 project

Copy `Makefile.cpu_synth` into the project root, next to the original makefile.
Copy `scripts/syn_cpu.tcl` into its `scripts/` folder. Keep the supplied
`design/ALU.v`, `decoder.v`, `register_file.v`, `cardinal_cpu.v`,
`cardinal_cpu_bp_v1.v`, and `BPB.v` in `design/`.

On the course machine, load the same environment used for the course example,
then run from the Phase 2 project root:

```sh
make -f Makefile.cpu_synth both
```

To run only one CPU:

```sh
make -f Makefile.cpu_synth baseline
make -f Makefile.cpu_synth bp
```

The default clock constraint is **5.0 ns**, matching the supplied course
`syn.tcl`. You can use another common target for both CPUs, for example:

```sh
make -f Makefile.cpu_synth both CLOCK_PERIOD_NS=1.45
```

The outputs are isolated in `synth_results/cardinal_cpu/` and
`synth_results/cardinal_cpu_bp_v1/`. Each contains `dc.log`, area, cell,
timing, power, and design-check reports under `report/`, plus Verilog, SDF,
and SDC files under `netlist/`. The original project's `report/` and
`netlist/` directories are not used by this makefile.

For an area or timing comparison, compare reports made with the **same**
`CLOCK_PERIOD_NS` and technology library. The 5 ns value is a synthesis
constraint, not proof that either CPU meets timing; inspect the timing report's
slack. `report_power` without switching activity is a vectorless estimate, so
it is suitable only as a rough comparison unless you provide activity data.

The scripts were checked against the supplied source-file/module names and
make dependencies. Design Compiler is not available in this local environment,
so the synthesis run itself has not been executed here.
