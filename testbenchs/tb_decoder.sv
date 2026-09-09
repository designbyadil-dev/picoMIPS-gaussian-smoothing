//-----------------------------------------------------
// File Name   : tb_decoder.sv
// Function    : Testbench for decoder.sv
//               Tests all 8 opcodes and all flag combinations
//               for BEQ and BNE
// Author      : ar7n25
//-----------------------------------------------------
`include "alucodes.sv"
`include "opcodes.sv"
`timescale 1ns/1ps

module tb_decoder;

logic [4:0] opcode;
logic       flags;
logic       PCincr, PCrelbranch;
logic [2:0] ALUfunc;
logic       imm, w, mac_en, mac_incr, use_mac_result;

decoder dut (.*);

int pass_count = 0, fail_count = 0;

// All signals pre-declared at module level so tasks can use them
bit ok;

task check(
    input [4:0]  op,
    input        flag_in,
    input        exp_PCincr, exp_PCrel,
    input [2:0]  exp_ALUfunc,
    input        exp_imm, exp_w, exp_mac_en, exp_mac_incr, exp_use_mac,
    input string desc
);
    opcode = op; flags = flag_in; #2;
    ok = 1;
    if (PCincr         !== exp_PCincr)   begin $error("FAIL [%s] PCincr=%0b exp=%0b",         desc, PCincr,         exp_PCincr);   ok=0; end
    if (PCrelbranch    !== exp_PCrel)    begin $error("FAIL [%s] PCrelbranch=%0b exp=%0b",     desc, PCrelbranch,    exp_PCrel);    ok=0; end
    if (ALUfunc        !== exp_ALUfunc)  begin $error("FAIL [%s] ALUfunc=%03b exp=%03b",       desc, ALUfunc,        exp_ALUfunc);  ok=0; end
    if (imm            !== exp_imm)      begin $error("FAIL [%s] imm=%0b exp=%0b",             desc, imm,            exp_imm);      ok=0; end
    if (w              !== exp_w)        begin $error("FAIL [%s] w=%0b exp=%0b",               desc, w,              exp_w);        ok=0; end
    if (mac_en         !== exp_mac_en)   begin $error("FAIL [%s] mac_en=%0b exp=%0b",          desc, mac_en,         exp_mac_en);   ok=0; end
    if (mac_incr       !== exp_mac_incr) begin $error("FAIL [%s] mac_incr=%0b exp=%0b",        desc, mac_incr,       exp_mac_incr); ok=0; end
    if (use_mac_result !== exp_use_mac)  begin $error("FAIL [%s] use_mac=%0b exp=%0b",         desc, use_mac_result, exp_use_mac);  ok=0; end
    if (ok) begin $display("PASS [%s]", desc); pass_count++; end
    else    fail_count++;
endtask

initial begin
    $display("=== tb_decoder ===");

    //            op    flag PCi PCr ALUf  imm w  mac  incr use
    check(`NOP,   0, 1, 0, `RNOP, 0, 0, 0, 0, 0, "NOP flag=0");
    check(`NOP,   1, 1, 0, `RNOP, 0, 0, 0, 0, 0, "NOP flag=1 ignored");

    check(`ADDI,  0, 1, 0, `RADD, 1, 1, 0, 0, 0, "ADDI");
    check(`SUBI,  0, 1, 0, `RSUB, 1, 1, 0, 0, 0, "SUBI");

    check(`MAC,   0, 1, 0, `RNOP, 0, 1, 1, 0, 1, "MAC mac_incr=0 (final tap)");
    check(`MACI,  0, 1, 0, `RNOP, 0, 1, 1, 1, 1, "MACI mac_incr=1 (taps 1-4)");

    check(`BEQ,   0, 1, 0, `RNOP, 0, 0, 0, 0, 0, "BEQ Z=0 no branch");
    check(`BEQ,   1, 0, 1, `RNOP, 0, 0, 0, 0, 0, "BEQ Z=1 branch taken");

    check(`BNE,   0, 0, 1, `RNOP, 0, 0, 0, 0, 0, "BNE Z=0 branch taken");
    check(`BNE,   1, 1, 0, `RNOP, 0, 0, 0, 0, 0, "BNE Z=1 no branch");

    check(`BRA,   0, 0, 1, `RNOP, 0, 0, 0, 0, 0, "BRA Z=0 always branch");
    check(`BRA,   1, 0, 1, `RNOP, 0, 0, 0, 0, 0, "BRA Z=1 always branch");

    // Unknown opcode → NOP behaviour
    opcode = 5'b11111; flags = 0; #2;
    if (PCincr !== 1 || w !== 0 || mac_en !== 0) begin
        $error("FAIL [default]: PCincr=%0b w=%0b mac_en=%0b", PCincr, w, mac_en);
        fail_count++;
    end else begin
        $display("PASS [default opcode → NOP]");
        pass_count++;
    end

    $display("─────────────────────────────");
    $display("RESULTS: %0d PASS  %0d FAIL", pass_count, fail_count);
    if (fail_count == 0) $display("ALL PASS ✓");
    $finish;
end

endmodule