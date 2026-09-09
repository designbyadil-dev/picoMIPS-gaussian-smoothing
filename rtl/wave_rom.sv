//-----------------------------------------------------
// File Name   : wave_rom.sv
// Function    : 256 x 8-bit ROM for noisy sine waveform
//               Loaded from wave.hex
// Author      : ar7n25
//-----------------------------------------------------
module wave_rom (
    input  logic [7:0] addr,
    output logic [7:0] data
);

logic [7:0] mem [0:255];

initial
    $readmemh("wave.hex", mem);

always_comb
    data = mem[addr];

endmodule
