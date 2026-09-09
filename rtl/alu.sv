//-----------------------------------------------------
// File Name   : alu.sv
// Function    : ALU for optimised picoMIPS
//               Operations: ADDI/SUBI only (add/sub with imm8)
//               Only Z flag output — N,C,V removed
//
// Author: tjk, optimised by ar7n25
//-----------------------------------------------------
`include "alucodes.sv"

module alu #(parameter n = 8) (
    input  logic [n-1:0] a, b,
    input  logic [2:0]   func,
    output logic         flags,     // Z flag only
    output logic [n-1:0] result
);

logic [n-1:0] ar, b1;

// Adder/subtractor core
always_comb begin
    b1 = (func == `RSUB) ? (~b + 1'b1) : b;
    ar = a + b1;
end

always_comb begin
    result = a;   // default passA

    case (func)
        `RA   : result = a;
        `RB   : result = b;
        `RADD : result = ar;
        `RSUB : result = ar;
        `RNOP : result = a;
        default: result = a;
    endcase

    // Z flag: set when result is zero
    flags = (result == {n{1'b0}});
end

endmodule
