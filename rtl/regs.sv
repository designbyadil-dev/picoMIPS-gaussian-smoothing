//-----------------------------------------------------
// File Name   : regs.sv
// Function    : picoMIPS register file (optimised)
//               %0 hardwired to zero — writes suppressed
//               %4 removed (unused scratch register)
//               3-bit addresses — gpr[6:0] array but only
//               indices 1,2,3,5,6 hold live flip-flops
//               Separate Waddr port
//               Rdata_acc: dedicated combinational read of gpr[5]
//               Asynchronous reset clears all registers to 0
// Author: tjk, optimised by ar7n25
//-----------------------------------------------------
module regs #(parameter n = 8)
(
    input  logic         clk,
    input  logic         reset,     // active-high reset
    input  logic         w,
    input  logic [n-1:0] Wdata,
    input  logic [2:0]   Raddr1,
    input  logic [2:0]   Raddr2,
    input  logic [2:0]   Waddr,
    output logic [n-1:0] Rdata1,
    output logic [n-1:0] Rdata2,
    output logic [n-1:0] Rdata_acc  // always reads gpr[5] for MAC input
);

logic [n-1:0] gpr [6:0];   // array kept at [6:0] for address compatibility

// Write with reset — gpr[0] never written (hardwired zero)
// gpr[4] never written (no instruction targets %4)
// Quartus will eliminate FFs for indices that are never written
always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        gpr[1] <= {n{1'b0}};
        gpr[2] <= {n{1'b0}};
        gpr[3] <= {n{1'b0}};
        gpr[5] <= {n{1'b0}};
        gpr[6] <= {n{1'b0}};
    end else if (w && Waddr != 3'd0) begin
        gpr[Waddr] <= Wdata;
    end
end

// Asynchronous read — %0 always returns 0
always_comb begin
    Rdata1    = (Raddr1 == 3'd0) ? {n{1'b0}} : gpr[Raddr1];
    Rdata2    = (Raddr2 == 3'd0) ? {n{1'b0}} : gpr[Raddr2];
    Rdata_acc = gpr[5];   // direct read of %5 — no acc_reg FF needed
end

endmodule