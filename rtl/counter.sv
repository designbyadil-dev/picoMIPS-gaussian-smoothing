//-----------------------------------------------------
// File Name   : counter.sv
// Function    : Clock divider for DE1-SoC FPGA
//               Divides 50 MHz board clock by 2^n
//               n=24 -> ~2.98 Hz (eliminates switch bounce)
// Author      : tjk, used by ar7n25
//-----------------------------------------------------
module counter #(parameter n = 24)  // divide by 2^n
(
    input  logic fastclk,   // 50 MHz board oscillator
    output logic clk        // slow clock ~3 Hz
);

logic [n-1:0] count;

always_ff @(posedge fastclk)
    count <= count + 1;

assign clk = count[n-1];   // MSB toggles at 50MHz / 2^n

endmodule




