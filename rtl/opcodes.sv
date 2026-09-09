//-----------------------------------------------------
// File Name   : opcodes.sv
// Function    : picoMIPS opcode definitions
//               16-bit ISA — 5-bit opcode [15:11]
//               8 instructions (added MACI)
//
//   MACI: MAC with auto-increment of wave address register
//
// Author: ar7n25
//-----------------------------------------------------

`define NOP   5'b00000   // no operation
`define ADDI  5'b00001   // %d = reg[%s] + imm5
`define SUBI  5'b00010   // %d = reg[%s] - imm5
`define MAC   5'b00011   // acc += W[reg[%d]]*imm5>>7
`define MACI  5'b00100   // acc += W[reg[%d]]*imm5>>7  then reg[%d]++
`define BEQ   5'b01000   // branch if Z=1  (PC-relative signed imm5)
`define BNE   5'b01001   // branch if Z=0
`define BRA   5'b01010   // branch always