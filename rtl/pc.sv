//-----------------------------------------------------
// File Name   : pc.sv
// Function    : picoMIPS Program Counter
//               4-bit PC — 16 instruction slots
//               PC-relative branches only
// Author: tjk, optimised by ar7n25
//-----------------------------------------------------
module pc #(parameter Psize = 4)   // 4-bit: 16 slots
(
    input  logic             clk,
    input  logic             reset,
    input  logic             PCincr,
    input  logic             PCrelbranch,
    input  logic [Psize-1:0] Branchaddr,
    output logic [Psize-1:0] PCout
);

logic [Psize-1:0] Rbranch;

always_comb begin
    if (PCincr)
        Rbranch = {{(Psize-1){1'b0}}, 1'b1};
    else
        Rbranch = Branchaddr;
end

always_ff @(posedge clk or posedge reset)
    if (reset)
        PCout <= {Psize{1'b0}};
    else if (PCincr | PCrelbranch)
        PCout <= PCout + Rbranch;

endmodule