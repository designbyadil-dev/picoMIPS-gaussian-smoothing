//-----------------------------------------------------
// File Name   : prog.sv
// Function    : Program memory — 16×16-bit
//               Psize=4 (16 slots), Isize=15 (16-bit)
// Author: tjk, optimised by ar7n25
//-----------------------------------------------------
module prog #(
    parameter Psize = 4,    // 4-bit PC — 16 slots
    parameter Isize = 15    // 16-bit instructions [15:0]
)(
    input  logic [Psize-1:0] address,
    output logic [Isize:0]   I
);

logic [Isize:0] progMem [0:(1<<Psize)-1];

initial
    $readmemh("prog_opt.hex", progMem, 0, (1<<Psize)-1);

always_comb
    I = progMem[address];

endmodule