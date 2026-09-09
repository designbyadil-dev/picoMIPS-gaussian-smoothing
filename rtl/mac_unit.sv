//-----------------------------------------------------
// File Name   : mac_unit.sv
// Function    : Multiply-accumulate unit for picoMIPS
//               Computes: result = acc + bits[14:7](wave_data * kernel)
//
//               Multiplication: signed(wave_data[7:0]) * {3'b0, imm5[4:0]}
//               16-bit product extracted at bits[14:7] (divides by 128)
//               This compensates for kernel values scaled by 2^7
//
//               Quartus infers this as a DSP9 block on Cyclone V
//               (multiply + accumulate in one DSP block)
//
// Author: ar7n25
//-----------------------------------------------------
module mac_unit #(parameter n = 8)
(
    input  logic [n-1:0] wave_data,   // signed 8-bit wave sample
    input  logic [4:0]   kernel,      // unsigned 5-bit kernel coefficient (imm5)
    input  logic [n-1:0] acc,         // current accumulator value (Rdata_acc)
    output logic [n-1:0] result       // acc + bits[14:7](wave_data * kernel)
);

logic [2*n-1:0] product;

// Signed × unsigned multiply — wave_data is signed, kernel is positive
assign product = $signed(wave_data) * $signed({3'b0, kernel});

// Extract bits[14:7]: compensates for kernel scaled up by 2^7
// Equivalent to: floor(wave_data * kernel / 128)
assign result = acc + product[14:7];

endmodule
