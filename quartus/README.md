# quartus/

Place your Quartus project files here once created:

- `picoMIPS.qpf` / `picoMIPS.qsf` — project and settings files
- `picoMIPS.sdc` — timing constraints
- Pin assignments for the DE1-SoC board (SW, LED, HEX, CLOCK_50)

Target device: **Cyclone V SoC, 5CSEMA5F31C6** (DE1-SoC board).

Set `rtl/picoMIPS.sv` alone as the top-level entity to reproduce the reported
cost figure (96 ALMs / 1 DSP block / 0 RAM bits), or `rtl/picoMIPS4test.sv`
for the full board demo including the clock divider (and optional 7-segment
display block, currently commented out in that file).
