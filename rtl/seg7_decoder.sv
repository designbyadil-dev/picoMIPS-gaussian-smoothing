//-----------------------------------------------------
// File Name   : seg7_decoder.sv
// Function    : 4-bit BCD to 7-segment decoder
//               Active LOW output (common anode DE1-SoC)
//
// Segment layout:
//    _
//   |_|   seg: 6543210
//   |_|        gfedcba
//
// Author: ar7n25
//-----------------------------------------------------
module seg7_decoder (
    input  logic [3:0]  bcd,    // digit 0-9, or special
    input  logic        blank,  // 1 = force all segments off
    output logic [6:0]  seg     // active LOW: 0=on, 1=off
);

always_comb begin
    if (blank) begin
        seg = 7'b1111111;   // all off
    end else begin
        case (bcd)
            4'd0:    seg = 7'b1000000;  //  0
            4'd1:    seg = 7'b1111001;  //  1
            4'd2:    seg = 7'b0100100;  //  2
            4'd3:    seg = 7'b0110000;  //  3
            4'd4:    seg = 7'b0011001;  //  4
            4'd5:    seg = 7'b0010010;  //  5
            4'd6:    seg = 7'b0000010;  //  6
            4'd7:    seg = 7'b1111000;  //  7
            4'd8:    seg = 7'b0000000;  //  8
            4'd9:    seg = 7'b0010000;  //  9
            4'd10:   seg = 7'b0111111;  //  - (minus, middle bar only)
            4'd11:   seg = 7'b1111001;  //  + approximation (like 1, top-right)
            default: seg = 7'b1111111;  //  blank
        endcase
    end
end

endmodule
