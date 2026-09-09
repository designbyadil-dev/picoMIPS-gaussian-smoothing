# sim/

This directory is for simulation-only files:

- `tb_picoMIPS.sv` — top-level testbench (drives `SW[9:0]`, checks `LED` against
  expected values). Referenced in `docs/report.pdf` §2.4 but not yet added here.
- `prog_opt.hex` — assembled 13-instruction program (see the program listing
  table in `docs/report.pdf`), loaded by `rtl/prog.sv` via `$readmemh`.
- `wave.hex` — 256-sample noisy waveform ROM image (provided on the ELEC6234
  notes site), loaded by `rtl/wave_rom.sv` via `$readmemh`.

Add these three files here before running ModelSim/Questa/Icarus Verilog.
For Quartus synthesis, copy `prog_opt.hex` and `wave.hex` into the Quartus
project directory as well (or add this folder to the project's search path).
