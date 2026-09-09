//-----------------------------------------------------
// File Name   : tb_prog.sv
// Function    : Testbench for prog.sv
//               Reads prog_opt.hex and verifies every
//               instruction at every PC address.
//               Checks full word, then key fields.
//               Updated for 96-ALM design: PC=0,10 use
//               ADDI %0,%3,0 (0x0860) instead of %4
// Author      : ar7n25
//-----------------------------------------------------
`include "opcodes.sv"
`timescale 1ns/1ps

module tb_prog;

parameter Psize = 4;
parameter Isize = 15;

logic [Psize-1:0] address;
logic [Isize:0]   I;

prog #(.Psize(Psize),.Isize(Isize)) dut (.address(address),.I(I));

// Field extraction
wire [4:0] opcode = I[15:11];
wire [2:0] rd     = I[10:8];
wire [2:0] rs     = I[7:5];
wire [4:0] imm5   = I[4:0];

int pass_count = 0, fail_count = 0;
bit ok;

// Signed imm5 conversion
function integer to_signed5(input [4:0] v);
    if (v[4]) to_signed5 = v - 32;
    else      to_signed5 = v;
endfunction

task check_word(
    input [Psize-1:0] addr,
    input [Isize:0]   exp_I,
    input string      desc
);
    address = addr; #2;
    if (I !== exp_I) begin
        $error("FAIL [%s] PC=%0d: got=0x%04h exp=0x%04h", desc, addr, I, exp_I);
        fail_count++;
    end else begin
        $display("PASS [%s] PC=%0d: 0x%04h  op=%05b %%d=%0d %%s=%0d imm=%0d",
                 desc, addr, I, opcode, rd, rs, to_signed5(imm5));
        pass_count++;
    end
endtask

task check_fields(
    input [Psize-1:0] addr,
    input [4:0] exp_op,
    input [2:0] exp_rd, exp_rs,
    input [4:0] exp_imm,
    input string desc
);
    address = addr; #2;
    ok = 1;
    if (opcode !== exp_op)  begin $error("FAIL [%s] opcode=%05b exp=%05b", desc, opcode, exp_op); ok=0; end
    if (rd     !== exp_rd)  begin $error("FAIL [%s] %%d=%0d exp=%0d",      desc, rd, exp_rd);     ok=0; end
    if (rs     !== exp_rs)  begin $error("FAIL [%s] %%s=%0d exp=%0d",      desc, rs, exp_rs);     ok=0; end
    if (imm5   !== exp_imm) begin $error("FAIL [%s] imm5=%05b exp=%05b",   desc, imm5, exp_imm);  ok=0; end
    if (ok) begin $display("PASS [%s] PC=%0d all fields correct", desc, addr); pass_count++; end
    else    fail_count++;
endtask

initial begin
    $display("=== tb_prog (96-ALM design) ===");

    // ============= Full word checks for all 13 instructions =====================
    check_word(4'd0,  16'h0860, "ADDI %0,%3,0  (test SW8)");
    check_word(4'd1,  16'h401F, "BEQ  -1       (wait SW8=0)");
    check_word(4'd2,  16'h0A20, "ADDI %2,%1,0  (latch i)");
    check_word(4'd3,  16'h1642, "SUBI %6,%2,2  (wave addr=i-2)");
    check_word(4'd4,  16'h0D00, "ADDI %5,%0,0  (clear acc)");
    check_word(4'd5,  16'h260C, "MACI %6,12    (K[0]=12)");
    check_word(4'd6,  16'h2618, "MACI %6,24    (K[1]=24)");
    check_word(4'd7,  16'h261D, "MACI %6,29    (K[2]=29 centre)");
    check_word(4'd8,  16'h2618, "MACI %6,24    (K[3]=24)");
    check_word(4'd9,  16'h1E0C, "MAC  %6,12    (K[4]=12 final)");
    check_word(4'd10, 16'h0860, "ADDI %0,%3,0  (test SW8)");
    check_word(4'd11, 16'h481F, "BNE  -1       (wait SW8=1)");
    check_word(4'd12, 16'h5014, "BRA  -12      (restart)");

    // ============ NOP padding ==============================
    check_word(4'd13, 16'h0000, "NOP padding PC=13");
    check_word(4'd14, 16'h0000, "NOP padding PC=14");
    check_word(4'd15, 16'h0000, "NOP padding PC=15");

    // ============== Field-level checks for critical instructions ===============
    check_fields(4'd0,  `ADDI, 3'd0, 3'd3, 5'd0,  "ADDI %0,%3,0  test SW8 (writes to %0, suppressed)");
    check_fields(4'd10, `ADDI, 3'd0, 3'd3, 5'd0,  "ADDI %0,%3,0  test SW8 again");
    check_fields(4'd5,  `MACI, 3'd6, 3'd0, 5'd12, "MACI K[0]=12  %d=6 imm=12");
    check_fields(4'd6,  `MACI, 3'd6, 3'd0, 5'd24, "MACI K[1]=24  %d=6 imm=24");
    check_fields(4'd7,  `MACI, 3'd6, 3'd0, 5'd29, "MACI K[2]=29  %d=6 imm=29 (centre)");
    check_fields(4'd8,  `MACI, 3'd6, 3'd0, 5'd24, "MACI K[3]=24  %d=6 imm=24");
    check_fields(4'd9,  `MAC,  3'd6, 3'd0, 5'd12, "MAC  K[4]=12  %d=6 imm=12");
    check_fields(4'd3,  `SUBI, 3'd6, 3'd2, 5'd2,  "SUBI %6,%2,2  %d=6 %s=2 imm=2");
    check_fields(4'd2,  `ADDI, 3'd2, 3'd1, 5'd0,  "ADDI %2,%1,0  latch i");
    check_fields(4'd4,  `ADDI, 3'd5, 3'd0, 5'd0,  "ADDI %5,%0,0  clear acc");

    // =========== Branch offset verification ====================
    // BEQ at PC=1: imm5=11111 → signed=-1 → PC=1+(-1)=0
    address = 4'd1; #2;
    if (imm5 !== 5'b11111) begin
        $error("FAIL [BEQ offset]: imm5=%05b exp=11111", imm5); fail_count++;
    end else begin
        $display("PASS [BEQ offset] imm5=11111 (-1) → PC=0"); pass_count++;
    end

    // BNE at PC=11: imm5=11111 → -1 → PC=11+(-1)=10
    address = 4'd11; #2;
    if (imm5 !== 5'b11111) begin
        $error("FAIL [BNE offset]: imm5=%05b exp=11111", imm5); fail_count++;
    end else begin
        $display("PASS [BNE offset] imm5=11111 (-1) → PC=10"); pass_count++;
    end

    // BRA at PC=12: imm5=10100 → signed=-12 → PC=12+(-12)=0
    address = 4'd12; #2;
    if (imm5 !== 5'b10100) begin
        $error("FAIL [BRA offset]: imm5=%05b exp=10100", imm5); fail_count++;
    end else begin
        $display("PASS [BRA offset] imm5=10100 (-12) → PC=0"); pass_count++;
    end

    // ============ Kernel value symmetry check ====================
    address = 4'd5; #2;
    if (imm5 !== 5'd12) begin $error("FAIL [symmetry K[0]]"); fail_count++; end
    else                begin $display("PASS [K symmetric K[0]=12]"); pass_count++; end

    address = 4'd9; #2;
    if (imm5 !== 5'd12) begin $error("FAIL [symmetry K[4]]"); fail_count++; end
    else                begin $display("PASS [K symmetric K[4]=12]"); pass_count++; end

    address = 4'd6; #2;
    if (imm5 !== 5'd24) begin $error("FAIL [symmetry K[1]]"); fail_count++; end
    else                begin $display("PASS [K symmetric K[1]=24]"); pass_count++; end

    address = 4'd8; #2;
    if (imm5 !== 5'd24) begin $error("FAIL [symmetry K[3]]"); fail_count++; end
    else                begin $display("PASS [K symmetric K[3]=24]"); pass_count++; end

    $display("=====================================================");
    $display("RESULTS: %0d PASS  %0d FAIL", pass_count, fail_count);
    if (fail_count == 0) $display("ALL PASS");
    $finish;
end

endmodule
