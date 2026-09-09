//-----------------------------------------------------
// File Name   : tb_alu.sv
// Function    : Testbench for alu.sv
//               Tests: RADD, RSUB, RA, RB, RNOP
//               Z flag assertion on zero result
//               Signed arithmetic verification
// Author      : ar7n25
//-----------------------------------------------------
`include "alucodes.sv"
`timescale 1ns/1ps

module tb_alu;

parameter n = 8;

logic [n-1:0] a, b;
logic [2:0]   func;
logic         flags;
logic [n-1:0] result;

alu #(.n(n)) dut (.a(a),.b(b),.func(func),.flags(flags),.result(result));

int pass_count = 0, fail_count = 0;

task automatic check(
    input [n-1:0]  ta, tb,
    input [2:0]    tfunc,
    input [n-1:0]  exp_result,
    input          exp_flag,
    input string   desc
);
    a = ta; b = tb; func = tfunc; #2;
    if (result !== exp_result || flags !== exp_flag) begin
        $error("FAIL [%s]: a=%0d b=%0d func=%03b → result=%0d (exp %0d) Z=%0b (exp %0b)",
               desc, $signed(ta), $signed(tb), tfunc,
               $signed(result), $signed(exp_result), flags, exp_flag);
        fail_count++;
    end else begin
        $display("PASS [%s]  result=%0d  Z=%0b", desc, $signed(result), flags);
        pass_count++;
    end
endtask

initial begin
    $display("=== tb_alu ===");

    // RADD
    check(8'd10,  8'd5,   `RADD, 8'd15,   0, "RADD 10+5=15");
    check(8'd0,   8'd0,   `RADD, 8'd0,    1, "RADD 0+0=0  Z=1");
    check(8'hFF,  8'd1,   `RADD, 8'd0,    1, "RADD -1+1=0  Z=1");
    check(8'd100, 8'd28,  `RADD, 8'd128,  0, "RADD 100+28=128");
    check(8'hFA,  8'd10,  `RADD, 8'd4,    0, "RADD -6+10=+4 signed");

    // RSUB
    check(8'd15,  8'd5,   `RSUB, 8'd10,   0, "RSUB 15-5=10");
    check(8'd5,   8'd5,   `RSUB, 8'd0,    1, "RSUB 5-5=0  Z=1");
    check(8'd0,   8'd1,   `RSUB, 8'hFF,   0, "RSUB 0-1=-1");
    check(8'hFE,  8'hFE,  `RSUB, 8'd0,    1, "RSUB -2-(-2)=0  Z=1");
    check(8'd50,  8'd2,   `RSUB, 8'd48,   0, "RSUB 50-2=48");

    // RA (pass A)
    check(8'd42,  8'd99,  `RA,   8'd42,   0, "RA passA=42");
    check(8'd0,   8'd99,  `RA,   8'd0,    1, "RA passA=0  Z=1");

    // RB (pass B)
    check(8'd99,  8'd42,  `RB,   8'd42,   0, "RB passB=42");
    check(8'd99,  8'd0,   `RB,   8'd0,    1, "RB passB=0  Z=1");

    // RNOP (pass A, same as RA)
    check(8'd77,  8'd33,  `RNOP, 8'd77,   0, "RNOP passA=77");
    check(8'd0,   8'd33,  `RNOP, 8'd0,    1, "RNOP passA=0  Z=1");

    // Gaussian program specific: SW8=0 → Z flag test
    // ADDI %4,%3,0 where %3=SW[8]=0 → result=0, Z=1
    check(8'd0,   8'd0,   `RADD, 8'd0,    1, "SW8=0 test: ADDI→Z=1");
    // ADDI %4,%3,0 where %3=SW[8]=1 → result=1, Z=0
    check(8'd1,   8'd0,   `RADD, 8'd1,    0, "SW8=1 test: ADDI→Z=0");

    $display("RESULTS: %0d PASS  %0d FAIL", pass_count, fail_count);
    if (fail_count == 0) $display("ALL PASS ✓");
    $finish;
end

endmodule
