# ID-resolved branch predictor test

The loop runs four times. Its BEZ is taken four times, so a counter starting at
`00` trains through `01`, `10`, and `11`; later executions should be predicted
taken. Its BNEZ is taken three times and then not taken, testing recovery from
a trained taken prediction. Two more branches are not taken, and the final BEZ
is taken.

Memory locations 16 and 20 must stay zero because their stores are after
taken branches. Location 17 must be zero because the loop reaches count zero.
Locations 18, 19, and 21 must contain `a1b2c3d4e5f60718`.

With this directory copied under `tests/` in the Phase 2 simulation directory:

```sh
make test IMEM=tests/cardinal_bp_v1/imem.fill DMEM=tests/cardinal_bp_v1/dmem.fill EXPECTED=tests/cardinal_bp_v1/expected_dmem.dump
```

The Phase 2 makefile compiles every `design/*.v` file. Compile only one module
named `cardinal_cpu` at a time: use the version 1 CPU as the active top module
when running this test. To regenerate the files, run
`python -B tests/cardinal_bp_v1/generate.py`.
