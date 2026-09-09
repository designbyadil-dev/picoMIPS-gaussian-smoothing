# picoMIPS — 1D Gaussian Smoothing Processor (ELEC6234 Coursework)



## Overview

This repository contains a custom **picoMIPS** processor, designed and optimised in
SystemVerilog, that performs **1-dimensional Gaussian smoothing** of a noisy 256-sample
waveform stored in ROM. The processor reads a sample index from switches on a DE1-SoC
FPGA board, computes the 5-tap convolution `S[i] = Σ W[i-2+k]·K[k] / 128` using a
custom multiply-accumulate (MAC) instruction, and displays the result on LEDs / a
7-segment decimal display.

**Final synthesis result (Cyclone V SoC 5CSEMA5F31C6):** 96 ALMs, 1 DSP block,
0 memory bits → **cost = 96** (see `docs/report.pdf` for the full derivation and
optimisation history).

## Repository structure

```
.
├── rtl/            SystemVerilog source (synthesisable design)
│   ├── picoMIPS.sv          Top-level CPU (control path + datapath)
│   ├── picoMIPS4test.sv     FPGA top-level wrapper (clock divider + CPU)
│   ├── decoder.sv           Instruction decoder (8-instruction ISA)
│   ├── alu.sv                ALU (ADD/SUB, Z flag only)
│   ├── alucodes.sv          ALU function-code defines
│   ├── opcodes.sv           Opcode defines (NOP, ADDI, SUBI, MAC, MACI, BEQ, BNE, BRA)
│   ├── pc.sv                4-bit program counter, PC-relative branching
│   ├── prog.sv               16 x 16-bit program ROM ($readmemh)
│   ├── regs.sv               7 x 8-bit register file
│   ├── mac_unit.sv          Multiply-accumulate unit (maps to DSP9 block)
│   ├── wave_rom.sv          256 x 8-bit waveform ROM ($readmemh)
│   ├── seg7_decoder.sv      BCD → 7-segment decoder (bonus display)
│   └── counter.sv           Clock divider for FPGA demo (~3 Hz)
├── sim/             Testbenches and memory-init files (see note below)
├── quartus/         Quartus project files / synthesis reports (add .qpf, .qsf, etc.)
├── docs/            Coursework brief, instructions, and final report
│   ├── coursework_brief.pdf
│   ├── coursework_instructions.pdf
│   └── report.pdf
└── README.md
```

> **Note on missing memory-init files:** `prog.sv` and `wave_rom.sv` load their
> contents via `$readmemh("prog_opt.hex", ...)` and `$readmemh("wave.hex", ...)`
> respectively. These `.hex` files (the assembled program and the waveform
> lookup table) were not part of the uploaded set — add them to `sim/` (for
> ModelSim/Questa runs) and to the Quartus project directory (for synthesis)
> before simulating or building. The waveform file `wave.hex` is provided by
> the module on the ELEC6234 notes site; `prog_opt.hex` is the hand-assembled
> 13-instruction program listed in `docs/report.pdf`.
>
> A top-level testbench (`tb_picoMIPS.sv`, referenced in the report) is not
> yet included — add it to `sim/` if you want to reproduce the ModelSim
> results described in the report.

## Architecture summary

- **ISA:** 16-bit instructions — `[15:11] opcode(5) | [10:8] %d(3) | [7:5] %s(3) | [4:0] imm5(5)`
- **Instructions:** `NOP, ADDI, SUBI, MAC, MACI, BEQ, BNE, BRA`
- **Registers:** 7 × 8-bit (`%0` hardwired zero, `%1`/`%3` transparently read live
  switch values, `%5` is the MAC accumulator / LED output, `%6` is a dedicated
  wave-address register with auto-increment support for `MACI`)
- **I/O:** `SW[7:0]` = sample index, `SW[8]` = handshake, `SW[9]` = active-low
  reset, `LED[7:0]` = signed result, optional `HEX0–HEX3` = signed decimal display

Full architectural rationale, the six rounds of ALM optimisation (173 → 96 ALMs),
the fixed-point arithmetic derivation, and FPGA test results are documented in
`docs/report.pdf`.

## Getting started

1. **Simulate:** open `rtl/` and `sim/` in ModelSim/Questa (or Icarus Verilog),
   add the missing `.hex` files, and run the testbench.
2. **Synthesise:** create a Quartus project targeting Cyclone V SoC
   `5CSEMA5F31C6`, add all files under `rtl/`, and set `picoMIPS4test` (or
   `picoMIPS` alone, for the reported cost figure) as the top-level entity.
3. **FPGA demo:** program a DE1-SoC board, set `SW[9]` up to release reset,
   enter the sample index on `SW[7:0]`, then toggle `SW[8]` to trigger and hold
   the computation.

## License

**Academic Context:** This was developed as a coursework project for the ELEC6234 Embedded Processor Synthesis module at the University of Southampton. It is shared publicly for portfolio and educational reference purposes.
