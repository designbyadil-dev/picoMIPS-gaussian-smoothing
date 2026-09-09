//-----------------------------------------------------
// File Name   : picoMIPS4test.sv
// Function    : FPGA top-level wrapper for picoMIPS
//               Clock divider + CPU + 7-segment display
//
// DE1-SoC board connections:
//   fastclk    <- PIN_AF14  (50 MHz CLOCK_50)
//   SW[9]      <- active-low reset  (down=reset, up=run)
//   SW[8]      <- handshake         (up=compute, down=display)
//   SW[7:0]    <- sample index i    (binary, 0..255)
//   LED[7:0]   -> LEDR7..LEDR0     (raw 8-bit result, binary)
//   HEX3[6:0]  -> sign display      (- or +)
//   HEX2[6:0]  -> hundreds digit    (blank if < 100)
//   HEX1[6:0]  -> tens digit
//   HEX0[6:0]  -> units digit
//
// Display format: S[i] is 8-bit 2's complement (-128..+127)
//   HEX3 = sign (- or +)
//   HEX2 = hundreds (blank when |S[i]| < 100)
//   HEX1 = tens
//   HEX0 = units
//
// Author: ar7n25
//-----------------------------------------------------


//-----------------------------------------------------



// uncomment it  for testing and demo

module picoMIPS4test(
  input logic fastclk,  // 50MHz Altera DE0 clock
  input logic [9:0] SW, // Switches SW0..SW9
  output logic [7:0] LED); // LEDs
  
  logic clk; // slow clock, about 10Hz
  
  counter c (.fastclk(fastclk),.clk(clk)); // slow clk from counter
  
  // to obtain the cost figure, synthesise your design without the counter 
  // and the picoMIPS4test module using Cyclone IV E as target
  // and make a note of the synthesis statistics

  picoMIPS myDesign (.clk(clk), .SW(SW),.LED(LED));
  
endmodule 



//-----------------------------------------------------

/*

// with 7-segment display additional feature

module picoMIPS4test (
    input  logic        fastclk,    // 50 MHz board clock (PIN_AF14)
    input  logic [9:0]  SW,         // slide switches
    output logic [7:0]  LED,        // red LEDs (raw binary result)
    output logic [6:0]  HEX0,       // 7-segment: units
    output logic [6:0]  HEX1,       // 7-segment: tens
    output logic [6:0]  HEX2,       // 7-segment: hundreds (or blank)
    output logic [6:0]  HEX3        // 7-segment: sign
);

// -------------------------------------------------------
// Clock divider: 50 MHz -> ~3 Hz
// -------------------------------------------------------
logic clk;

counter #(.n(24)) u_counter (
    .fastclk (fastclk),
    .clk     (clk)
);

// -------------------------------------------------------
// picoMIPS CPU
// -------------------------------------------------------
picoMIPS u_cpu (
    .clk (clk),
    .SW  (SW),
    .LED (LED)
);

// -------------------------------------------------------
// 7-segment display logic
// Convert LED (8-bit 2's complement) to decimal + sign
// -------------------------------------------------------
logic        is_negative;
logic [7:0]  abs_val;
logic [3:0]  digit_h, digit_t, digit_u;
logic        blank_hundreds;

// Sign and absolute value
assign is_negative = LED[7];
assign abs_val     = is_negative ? (~LED + 8'd1) : LED;

// BCD decomposition (abs_val <= 128, so max 3 digits)
assign digit_h = abs_val / 100;
assign digit_t = (abs_val % 100) / 10;
assign digit_u = abs_val % 10;

// Blank hundreds when < 100
assign blank_hundreds = (digit_h == 4'd0);

// -------------------------------------------------------
// 7-segment instantiations
// -------------------------------------------------------

// HEX0: units digit (never blank)
seg7_decoder u_hex0 (
    .bcd   (digit_u),
    .blank (1'b0),
    .seg   (HEX0)
);

// HEX1: tens digit (never blank -- show 0 for single-digit values)
seg7_decoder u_hex1 (
    .bcd   (digit_t),
    .blank (1'b0),
    .seg   (HEX1)
);

// HEX2: hundreds digit (blank when value < 100)
seg7_decoder u_hex2 (
    .bcd   (digit_h),
    .blank (blank_hundreds),
    .seg   (HEX2)
);

// HEX3: sign -- use special codes
//   10 = minus (-)
//   11 = plus  (+)
seg7_decoder u_hex3 (
    .bcd   (4'd10),
    .blank (~is_negative),
    .seg   (HEX3)
);

endmodule

*/

//-----------------------------------------------------


