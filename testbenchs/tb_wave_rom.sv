//-----------------------------------------------------
// File Name   : tb_wave_rom.sv
// Function    : Testbench for wave_rom.sv (asynchronous)
//               Combinational read — no clock, no latency
//               Verifies key samples from wave.hex including
//               all 5 samples used in i=5 convolution
// Author      : ar7n25
//-----------------------------------------------------
`timescale 1ns/1ps

module tb_wave_rom;

logic [7:0]  addr;
logic [7:0]  data;

// Async ROM — no clk port
wave_rom dut (.addr(addr), .data(data));

int pass_count = 0, fail_count = 0;

// Combinational ROM: set addr, wait for propagation, check data
task automatic check(
    input [7:0] taddr,
    input [7:0] exp,
    input string desc
);
    addr = taddr; #2;   // combinational delay
    if (data !== exp) begin
        $error("FAIL [%s] addr=%0d: data=0x%02h (%0d) exp=0x%02h (%0d)",
               desc, taddr, data, $signed(data), exp, $signed(exp));
        fail_count++;
    end else begin
        $display("PASS [%s] W[%0d]=0x%02h (%0d)", desc, taddr, data, $signed(data));
        pass_count++;
    end
endtask

initial begin
    $display("=== tb_wave_rom (asynchronous — combinational read) ===");

    // i=5 convolution samples: W[3..7]
    check(8'd3,  8'h1A, "W[3]=+26  i=5 tap0");
    check(8'd4,  8'h10, "W[4]=+16  i=5 tap1");
    check(8'd5,  8'h13, "W[5]=+19  i=5 tap2 (centre)");
    check(8'd6,  8'h2A, "W[6]=+42  i=5 tap3");
    check(8'd7,  8'h1F, "W[7]=+31  i=5 tap4");

    // First few samples
    check(8'd0,  8'hF6, "W[0]=-10");
    check(8'd1,  8'h02, "W[1]=+2");
    check(8'd2,  8'h0F, "W[2]=+15");

    // Negative samples
    check(8'd64,  8'h06, "W[64]=+6");
    check(8'd80,  8'hBD, "W[80]=-67");




    // Boundary addresses
    check(8'd0,   8'hF6, "W[0]   boundary low");
    check(8'd255, 8'hEF, "W[255] boundary high");

    // Mid-range
    check(8'd100, 8'hA2, "W[100]=-94");
    check(8'd128, 8'h0A, "W[128] mid-range positive");
    check(8'd200, 8'hDA, "W[200]=-38");

    // Verify rapid sequential reads work (combinational — no pipeline)
    $display("--- Sequential address scan W[3..7] ---");
    addr = 8'd3; #2;
    if (data !== 8'h1A) begin $error("FAIL [seq] W[3]=%0d exp=26", $signed(data)); fail_count++; end
    else                begin $display("PASS [seq] W[3]=26"); pass_count++; end

    addr = 8'd4; #2;
    if (data !== 8'h10) begin $error("FAIL [seq] W[4]=%0d exp=16", $signed(data)); fail_count++; end
    else                begin $display("PASS [seq] W[4]=16"); pass_count++; end

    addr = 8'd5; #2;
    if (data !== 8'h13) begin $error("FAIL [seq] W[5]=%0d exp=19", $signed(data)); fail_count++; end
    else                begin $display("PASS [seq] W[5]=19"); pass_count++; end

    addr = 8'd6; #2;
    if (data !== 8'h2A) begin $error("FAIL [seq] W[6]=%0d exp=42", $signed(data)); fail_count++; end
    else                begin $display("PASS [seq] W[6]=42"); pass_count++; end

    addr = 8'd7; #2;
    if (data !== 8'h1F) begin $error("FAIL [seq] W[7]=%0d exp=31", $signed(data)); fail_count++; end
    else                begin $display("PASS [seq] W[7]=31"); pass_count++; end

    $display("---------------------------------------------");
    $display("RESULTS: %0d PASS  %0d FAIL", pass_count, fail_count);
    if (fail_count == 0) $display("ALL PASS");
    $finish;
end

endmodule
