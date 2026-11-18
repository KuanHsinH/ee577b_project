# Synthesis run log

This directory exists so the shell can open `report/test.log` before `make`
starts. Run the following from the project root on the course machine after
loading `setup_v1721.csh`:

```sh
make -B -f Makefile.cpu_synth both > report/test.log &
```

The per-CPU timing reports are written under `synth_results/`.
