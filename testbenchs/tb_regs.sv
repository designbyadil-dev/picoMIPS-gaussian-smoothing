//-----------------------------------------------------
// File Name   : tb_regs.sv
// Function    : Testbench for regs.sv (optimised)
//               Tests: write/read, %0 hardwired zero
//               (write suppressed by Waddr!=0 guard),
//               separate Waddr port (MAC scenario),
//               Rdata_acc always reads gpr[5],
//               asynchronous reset clears all registers
// Author      : ar7n25
//-----------------------------------------------------
`timescale 1ns/1ps

module tb_regs;

parameter n = 8;

logic         clk, reset, w;
logic [n-1:0] Wdata;
logic [2:0]   Raddr1, Raddr2, Waddr;
logic [n-1:0] Rdata1, Rdata2, Rdata_acc;

regs #(.n(n)) dut (.*);

initial clk = 0;
always #5 clk = ~clk;

int pass_count = 0, fail_count = 0;

task automatic write_reg(input [2:0] addr, input [n-1:0] data);
    Waddr = addr; Wdata = data; w = 1;
    @(posedge clk); #1;
    w = 0;
endtask

task automatic check_read(
    input [2:0]  addr1, addr2,
    input [n-1:0] exp1, exp2,
    input string desc
);
    Raddr1 = addr1; Raddr2 = addr2; #2;
    if (Rdata1 !== exp1) begin
        $error("FAIL [%s] Rdata1[%%d=%0d]=%0d exp=%0d", desc, addr1, $signed(Rdata1), $signed(exp1));
        fail_count++;
    end else begin
        $display("PASS [%s] Rdata1[%%%0d]=%0d", desc, addr1, $signed(Rdata1));
        pass_count++;
    end
    if (Rdata2 !== exp2) begin
        $error("FAIL [%s] Rdata2[%%d=%0d]=%0d exp=%0d", desc, addr2, $signed(Rdata2), $signed(exp2));
        fail_count++;
    end else begin
        $display("PASS [%s] Rdata2[%%%0d]=%0d", desc, addr2, $signed(Rdata2));
        pass_count++;
    end
endtask

task automatic check_acc(input [n-1:0] exp, input string desc);
    #2;
    if (Rdata_acc !== exp) begin
        $error("FAIL [%s] Rdata_acc=%0d exp=%0d", desc, $signed(Rdata_acc), $signed(exp));
        fail_count++;
    end else begin
        $display("PASS [%s] Rdata_acc=%0d", desc, $signed(Rdata_acc));
        pass_count++;
    end
endtask

initial begin
    $display("=== tb_regs (96-ALM design, async reset, %%0 write-suppressed) ===");
    reset = 1; w = 0; Wdata = 0; Waddr = 0; Raddr1 = 0; Raddr2 = 0;
    @(posedge clk); #1;

    // -- Asynchronous reset clears all registers --
	for (int i = 0; i < 7; i++) begin
        if (i == 4) continue;  // %4 removed — not reset, not used
		
        Raddr1 = i[2:0]; #2;
        if (Rdata1 !== 8'd0) begin
            $error("FAIL [reset] gpr[%0d]=%0d not 0", i, Rdata1); fail_count++;
        end else begin
            $display("PASS [reset] gpr[%0d]=0", i); pass_count++;
        end
    end
    check_acc(8'd0, "Rdata_acc after reset");
    reset = 0;

    // -- %0 hardwired to zero: write suppressed by Waddr!=0 guard --
    write_reg(3'd0, 8'd99);
    Raddr1 = 3'd0; #2;
    if (Rdata1 !== 8'd0) begin
        $error("FAIL [%%0 write-suppressed]: Rdata1=%0d exp=0", Rdata1); fail_count++;
    end else begin $display("PASS [%%0 write-suppressed: write 99 had no effect]"); pass_count++; end

    // -- Write and read back live registers --
    write_reg(3'd1, 8'd42);
    check_read(3'd1, 3'd0, 8'd42, 8'd0, "write %1=42, %0=0");

    write_reg(3'd2, 8'd100);
    check_read(3'd2, 3'd1, 8'd100, 8'd42, "write %2=100");

    write_reg(3'd3, 8'd1);
    check_read(3'd3, 3'd2, 8'd1, 8'd100, "write %3=1");

    // -- %5 (accumulator): verify Rdata_acc tracks it --
    write_reg(3'd5, 8'd18);
    check_read(3'd5, 3'd5, 8'd18, 8'd18, "write %5=18");
    check_acc(8'd18, "Rdata_acc=18 after write %5");

    write_reg(3'd5, 8'd60);
    check_acc(8'd60, "Rdata_acc=60 after update %5");

    // -- %6 (wave address) --
    write_reg(3'd6, 8'd3);
    check_read(3'd6, 3'd5, 8'd3, 8'd60, "write %6=3 (wave addr), %5=60");

    // -- MAC scenario: Waddr=%5 while Raddr2=%6 --
    // MACI writes mac_result to %5 but needs to read %6 as wave address
    // Waddr is decoupled from Raddr2
    Raddr2 = 3'd6;   // read wave address from %6
    Waddr  = 3'd5;   // write result to %5
    Wdata  = 8'd9;   // mac_result (partial sum)
    w = 1;
    @(posedge clk); #1; w = 0;
    // Rdata2 should still be %6=3 (wave addr unchanged)
    Raddr2 = 3'd6; #2;
    if (Rdata2 !== 8'd3) begin
        $error("FAIL [MAC scenario] Rdata2[%%6]=%0d exp=3", Rdata2); fail_count++;
    end else begin $display("PASS [MAC scenario] Rdata2[%%6]=3 (wave addr unchanged)"); pass_count++; end
    check_acc(8'd9, "Rdata_acc=9 after MAC write to %5");

    // -- Write disabled when w=0 --
    Waddr = 3'd1; Wdata = 8'd0; w = 0;
    @(posedge clk); #1;
    check_read(3'd1, 3'd0, 8'd42, 8'd0, "no write when w=0, %1 unchanged");

    // -- Mid-execution reset (asynchronous: immediate effect) --
    reset = 1;
    #1;  // async reset takes effect immediately, no clock edge needed
    Raddr1 = 3'd1; Raddr2 = 3'd5; #2;
    if (Rdata1 !== 8'd0 || Rdata2 !== 8'd0) begin
        $error("FAIL [async reset] gpr[1]=%0d gpr[5]=%0d not 0", Rdata1, Rdata2); fail_count++;
    end else begin $display("PASS [async reset] all registers cleared immediately"); pass_count++; end
    check_acc(8'd0, "Rdata_acc=0 after async reset");
    @(posedge clk); #1;
    reset = 0;

    // -- Verify registers work after reset release --
    write_reg(3'd2, 8'd77);
    check_read(3'd2, 3'd0, 8'd77, 8'd0, "write %2=77 after reset release");

    $display("---------------------------------------------");
    $display("RESULTS: %0d PASS  %0d FAIL", pass_count, fail_count);
    if (fail_count == 0) $display("ALL PASS");
    $finish;
end

endmodule
