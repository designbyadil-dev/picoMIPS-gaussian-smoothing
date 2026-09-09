//-----------------------------------------------------
// File Name   : tb_pc.sv
// Function    : Testbench for pc.sv
//               Tests: reset, increment, forward branch,
//               backward branch (-1, -12), hold (no control),
//               mid-execution reset, wrap-around boundary
// Author      : ar7n25
//-----------------------------------------------------
`timescale 1ns/1ps

module tb_pc;

parameter Psize = 4;

logic             clk, reset, PCincr, PCrelbranch;
logic [Psize-1:0] Branchaddr;
logic [Psize-1:0] PCout;

pc #(.Psize(Psize)) dut (.*);

initial clk = 0;
always #5 clk = ~clk;

int pass_count = 0, fail_count = 0;

task automatic tick(input [Psize-1:0] expected, input string desc);
    @(posedge clk); #1;
    if (PCout !== expected) begin
        $error("FAIL [%s]: PCout=%0d exp=%0d", desc, PCout, expected);
        fail_count++;
    end else begin
        $display("PASS [%s]: PC=%0d", desc, PCout);
        pass_count++;
    end
endtask

initial begin
    $display("=== tb_pc ===");
    reset = 1; PCincr = 0; PCrelbranch = 0; Branchaddr = 0;

    // Reset
    @(posedge clk); #1;
    if (PCout !== 0) begin $error("FAIL [reset]: PCout=%0d", PCout); fail_count++; end
    else             begin $display("PASS [reset]: PC=0"); pass_count++; end

    // Sequential increment
    reset = 0; PCincr = 1; PCrelbranch = 0;
    tick(4'd1,  "PC=1 after incr");
    tick(4'd2,  "PC=2 after incr");
    tick(4'd3,  "PC=3 after incr");
    tick(4'd4,  "PC=4 after incr");

    // Forward branch +3 from PC=4 → PC=7
    PCincr = 0; PCrelbranch = 1; Branchaddr = 4'd3;
    tick(4'd7,  "PC=7 after +3 branch");

    // Resume increment
    PCincr = 1; PCrelbranch = 0;
    tick(4'd8,  "PC=8");
    tick(4'd9,  "PC=9");
    tick(4'd10, "PC=10");

    // Backward branch -1 (4'b1111 = -1 in 4-bit 2's complement) from PC=10 → 9
    PCincr = 0; PCrelbranch = 1; Branchaddr = 4'b1111;
    tick(4'd9,  "PC=9 after -1 branch");

    // Advance to PC=12, then BRA -12 → PC=0 (the actual program restart)
    PCincr = 1; PCrelbranch = 0;
    tick(4'd10, "PC=10");
    tick(4'd11, "PC=11");
    tick(4'd12, "PC=12");

    // BRA -12: 4-bit 2's complement = 4'b0100 = -12 mod 16 = 4
    // 12 + (-12) = 0 — in 4-bit arithmetic: 12 + 4 = 16 = 0 (overflow)
    PCincr = 0; PCrelbranch = 1; Branchaddr = 4'd4; // -12 in 4-bit = 4
    tick(4'd0,  "PC=0 after BRA -12 (restart)");

    // Hold: both PCincr=0 PCrelbranch=0 — PC must not change
    PCincr = 0; PCrelbranch = 0;
    @(posedge clk); #1;
    if (PCout !== 4'd0) begin $error("FAIL [hold]: PCout=%0d exp=0", PCout); fail_count++; end
    else                begin $display("PASS [hold at 0]"); pass_count++; end

    // Mid-execution reset
    PCincr = 1; PCrelbranch = 0;
    tick(4'd1, "PC=1 before mid-reset");
    tick(4'd2, "PC=2");
    reset = 1;
    tick(4'd0, "PC=0 after mid-reset");
    reset = 0;
    tick(4'd1, "PC=1 after reset release");

    // BEQ -1 equivalent: from PC=1, offset=-1 → PC=0
    // (used in program: loop while SW8=0)
    PCincr = 0; PCrelbranch = 1; Branchaddr = 4'b1111; // -1
    tick(4'd0, "PC=0 after BEQ -1 (SW8 loop)");

    $display("─────────────────────────────");
    $display("RESULTS: %0d PASS  %0d FAIL", pass_count, fail_count);
    if (fail_count == 0) $display("ALL PASS ✓");
    $finish;
end

endmodule
