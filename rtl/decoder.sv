//-----------------------------------------------------
// File Name   : decoder.sv
// Function    : picoMIPS decoder — 16-bit ISA, 5-bit opcode
//               8 instructions including MACI
//               Z flag only
//
// Author: ar7n25
//-----------------------------------------------------
`include "alucodes.sv"
`include "opcodes.sv"

module decoder (
    input  logic [4:0] opcode,
    input  logic       flags,
    output logic       PCincr,
    output logic       PCrelbranch,
    output logic [2:0] ALUfunc,
    output logic       imm,
    output logic       w,
    output logic       mac_en,
    output logic       mac_incr,      
    output logic       use_mac_result
);

logic takeBranch;

always_comb begin
    PCincr         = 1'b1;
    PCrelbranch    = 1'b0;
    ALUfunc        = `RNOP;
    imm            = 1'b0;
    w              = 1'b0;
    mac_en         = 1'b0;
    mac_incr       = 1'b0;
    use_mac_result = 1'b0;
    takeBranch     = 1'b0;

    case (opcode)
        `NOP  : ;
        `ADDI : begin w = 1'b1; imm = 1'b1; ALUfunc = `RADD; end
        `SUBI : begin w = 1'b1; imm = 1'b1; ALUfunc = `RSUB; end

        `MAC  : begin
                    w = 1'b1;
                    mac_en         = 1'b1;
                    use_mac_result = 1'b1;
                end

        `MACI : begin                        
                    w = 1'b1;
                    mac_en         = 1'b1;
                    mac_incr       = 1'b1;   
                    use_mac_result = 1'b1;
                end

        `BEQ  : takeBranch =  flags;
        `BNE  : takeBranch = ~flags;
        `BRA  : takeBranch = 1'b1;
        default: ;
    endcase

    if (takeBranch) begin
        PCincr      = 1'b0;
        PCrelbranch = 1'b1;
    end
end

endmodule