//-----------------------------------------------------
// File Name   : tb_mac_unit.sv
// Function    : Testbench for mac_unit.sv
//               Tests all 5 Gaussian taps for i=5,
//               negative wave samples, zero cases,
//               all kernel values 1..31
// Author      : ar7n25
//-----------------------------------------------------
`timescale 1ns/1ps

module tb_mac_unit;

parameter n = 8;

logic [n-1:0] wave_data;
logic [4:0]   kernel;
logic [n-1:0] acc;
logic [n-1:0] result;

mac_unit #(.n(n)) dut (.wave_data(wave_data),.kernel(kernel),.acc(acc),.result(result));

int pass_count = 0, fail_count = 0;

// Reference model ? declared at module level (no automatic needed)
logic [15:0] ref_product;
logic [7:0]  ref_result;

task check(
    input [n-1:0] twave, tacc,
    input [4:0]   tkernel,
    input [n-1:0] exp_result,
    input string  desc
);
    wave_data = twave; kernel = tkernel; acc = tacc; #2;
    if (result !== exp_result) begin
        $error("FAIL [%s]: W=%0d K=%0d acc=%0d ? got=%0d exp=%0d",
               desc, $signed(twave), tkernel, $signed(tacc),
               $signed(result), $signed(exp_result));
        fail_count++;
    end else begin
        $display("PASS [%s]  W=%0d K=%0d acc=%0d ? %0d",
                 desc, $signed(twave), tkernel, $signed(tacc), $signed(result));
        pass_count++;
    end
endtask

// Compute expected result the same way the hardware does
function logic [7:0] mac_ref(input [7:0] w, input [4:0] k, input [7:0] a);
    logic [15:0] p;
    p = $signed(w) * $signed({3'b0, k});
    mac_ref = a + p[14:7];
endfunction

initial begin
    $display("=== tb_mac_unit ===");
    $display("Formula: result = acc + bits[14:7](signed(W) * {3b0,K})");

    // Zero cases
    check(8'd0,   8'd0,  5'd12, 8'd0, "0*12+0=0");
    check(8'd26,  8'd0,  5'd0,  8'd0, "26*0+0=0");

    // i=5 convolution: W[3]=26, W[4]=16, W[5]=19, W[6]=42, W[7]=31
    // K=[12,24,29,24,12]
    check(8'h1A, 8'd0,  5'd12, mac_ref(8'h1A,5'd12,8'd0),  "tap0 W[3]=26 K=12 acc=0  ?2");
    check(8'h10, 8'd2,  5'd24, mac_ref(8'h10,5'd24,8'd2),  "tap1 W[4]=16 K=24 acc=2  ?5");
    check(8'h13, 8'd5,  5'd29, mac_ref(8'h13,5'd29,8'd5),  "tap2 W[5]=19 K=29 acc=5  ?9");
    check(8'h2A, 8'd9,  5'd24, mac_ref(8'h2A,5'd24,8'd9),  "tap3 W[6]=42 K=24 acc=9  ?16");
    check(8'h1F, 8'd16, 5'd12, mac_ref(8'h1F,5'd12,8'd16), "tap4 W[7]=31 K=12 acc=16 ?18");

    // Final result check
    wave_data = 8'h1F; kernel = 5'd12; acc = 8'd16; #2;
    if (result !== 8'd18) begin
        $error("FAIL [i=5 final]: result=%0d exp=18", $signed(result));
        fail_count++;
    end else begin
        $display("PASS [i=5 final result = +18] ?");
        pass_count++;
    end

    // Negative wave samples
    check(8'hF6, 8'd0, 5'd12, mac_ref(8'hF6,5'd12,8'd0), "neg W=-10 K=12");
    check(8'hC4, 8'd0, 5'd29, mac_ref(8'hC4,5'd29,8'd0), "neg W=-60 K=29");
    check(8'h80, 8'd0, 5'd29, mac_ref(8'h80,5'd29,8'd0), "neg W=-128 K=29 (min)");
    check(8'h7F, 8'd0, 5'd29, mac_ref(8'h7F,5'd29,8'd0), "pos W=+127 K=29 (max)");

    // Non-zero acc with negative wave
    check(8'h1A, 8'hFE, 5'd12, mac_ref(8'h1A,5'd12,8'hFE), "W=26 K=12 acc=-2");

    // All kernel values 1..31 for W=19
    begin
        int k_fail = 0;
        for (int k = 1; k < 32; k++) begin
            wave_data = 8'd19; kernel = k[4:0]; acc = 8'd0; #2;
            ref_result = mac_ref(8'd19, k[4:0], 8'd0);
            if (result !== ref_result) begin
                $error("FAIL [K=%0d]: result=%0d exp=%0d", k, $signed(result), $signed(ref_result));
                k_fail++;
                fail_count++;
            end
        end
        if (k_fail == 0) begin
            $display("PASS [all K=1..31 verified for W=19]");
            pass_count++;
        end
    end

    $display("=====================================================");
    $display("RESULTS: %0d PASS  %0d FAIL", pass_count, fail_count);
    if (fail_count == 0) $display("ALL PASS ?");
    $finish;
end

endmodule