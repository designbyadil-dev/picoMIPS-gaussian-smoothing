# picoMIPS — 1D Gaussian Smoothing Processor

Custom picoMIPS processor, designed and optimised in SystemVerilog, that
performs 1D Gaussian smoothing of a noisy 256-sample waveform stored in ROM,
demonstrated on an Intel Cyclone V SoC (DE1-SoC).

Reads a sample index from switches, computes the 5-tap convolution
`S[i] = Σ W[i-2+k]·K[k] / 128` via a custom multiply-accumulate (`MAC`/`MACI`)
instruction, and displays the result on LEDs (plus an optional 7-segment
signed decimal display).

**Final synthesis result:** 96 ALMs, 1 DSP block, 0 memory bits 

## Design

- **ISA:** 16-bit instructions — `[15:11] opcode(5) | [10:8] %d(3) | [7:5] %s(3) | [4:0] imm5(5)`
- **Instructions:** `NOP, ADDI, SUBI, MAC, MACI, BEQ, BNE, BRA`
- **Registers:** 7 × 8-bit (`%0` hardwired zero, `%1`/`%3` read live switch
  values, `%5` = accumulator/LED, `%6` = wave-address register with
  auto-increment via `MACI`)
- **I/O:** `SW[7:0]` sample index, `SW[8]` handshake, `SW[9]` active-low
  reset, `LED[7:0]` signed result

## Structure

```
rtl/          picoMIPS, picoMIPS4test, decoder, alu, pc, prog, regs,
              mac_unit, wave_rom, seg7_decoder, counter
testbench/    testbenches 
hex_files/    prog_opt.hex + wave.hex
quartus/      Quartus project files (Cyclone V 5CSEMA5F31C6)
docs/         full report
```

## Usage

1. **Simulate:** run the testbenches under `sim/` against `rtl/` in
   ModelSim/Questa or Icarus Verilog.
2. **Synthesise:** create a Quartus project targeting Cyclone V SoC
   `5CSEMA5F31C6`, add `rtl/` sources, set `picoMIPS` (for the reported cost
   figure) or `picoMIPS4test` (full board demo) as top-level.
3. **Demo:** program a DE1-SoC. `SW9` up = release reset, enter the sample
   index on `SW0–SW7`, toggle `SW8` to trigger and hold the computation.

## License

**Academic Context:** Developed as a coursework project for the ELEC6234
Embedded Processor Synthesis module at the University of Southampton. Shared
publicly for portfolio and educational reference purposes.


