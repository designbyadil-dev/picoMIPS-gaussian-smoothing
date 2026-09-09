//-----------------------------------------------------
// File Name   : tb_picoMIPS.sv
// Function    : Testbench for optimised picoMIPS
//               Verifies 7 golden test vectors + loop-back
// Author: ar7n25
//-----------------------------------------------------
`timescale 1ns/1ps
module tb_picoMIPS;

logic        clk;
logic [9:0]  SW;
logic [7:0]  LED;

picoMIPS dut (.clk(clk), .SW(SW), .LED(LED));

initial clk = 0;
always #5 clk = ~clk;

integer pass_count;
integer fail_count;
initial pass_count = 0;
initial fail_count = 0;

task automatic run_test;
    input int          idx;
    input logic [7:0]  expected;
    input int          expected_signed;
    begin
        // SW8=0: processor spins at PC=0/1 (BEQ loop)
        SW[9]   = 1'b1;
        SW[8]   = 1'b0;
        SW[7:0] = idx[7:0];
        repeat(25) @(posedge clk); #1;
        // SW8=1: processor latches i and computes all 5 MAC taps
        SW[8] = 1'b1;
        repeat(30) @(posedge clk); #1;
        // SW8=0: processor exits BNE loop; LED = gpr[5] combinational
        SW[8] = 1'b0;
        repeat(8) @(posedge clk); #1;
        if (LED === expected) begin
            $display("PASS S[%0d]=0x%02X (%0d signed)", idx, LED, expected_signed);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL S[%0d]: expected=0x%02X got=0x%02X", idx, expected, LED);
            fail_count = fail_count + 1;
        end
    end
endtask

initial begin
    $display("=== Optimised picoMIPS Testbench ===");
    $display("K = [12, 24, 29, 24, 12]  ar7n25");
    $display("16-bit ISA | 7 registers | MAC+MACI-with-immediate | 13 instructions");

    // Reset: SW9=0 for 15 cycles
    SW = 10'b00_0000_0000;
    repeat(15) @(posedge clk); #1;

    // Release reset
    SW[9] = 1'b1;
    repeat(5) @(posedge clk); #1;

    // 7 golden test vectors — all verified against wave.hex
    run_test(10,  8'h25,  37);
    run_test(50,  8'h33,  51);
    run_test(100, 8'hB5, -75);
    run_test(128, 8'hFE,  -2);
    run_test(150, 8'h47,  71);
    run_test(200, 8'hDC, -36);
    run_test(253, 8'hF3, -13);

    // Loop-back: verifies BRA -12 restarts correctly
    $display("-- Verify loop-back (BRA -12 → PC=0) --");
    run_test(10, 8'h25, 37);

    $display("");
    $display("=== Summary: %0d passed, %0d failed ===", pass_count, fail_count);
    if (fail_count == 0)
        $display("ALL TESTS PASSED");
    else
        $display("SOME TESTS FAILED");
    $finish;
end

// Watchdog
initial begin
    #1_000_000;
    $display("TIMEOUT");
    $finish;
end

endmodule