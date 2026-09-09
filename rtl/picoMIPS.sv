//-----------------------------------------------------
// File Name   : picoMIPS.sv
// Function    : Optimised picoMIPS top-level
//               1D Gaussian: S[i] = sum W[i-2+k]*K[k]/128
//               K = [12,24,29,24,12]  ar7n25
//
// Optimisations vs 134 ALM baseline:
//   A. MACI instruction: MAC + auto-increment wave_addr_reg
//      Removes 4 × ADDI %6,%6,1 → program 17→13 instructions
//   B. 4-bit PC: 13 instructions fit in 16 slots
//      ROM shrinks 32×16 → 16×16 bits (~6-8 ALMs saved)
//   C. acc_reg removed: MAC reads gpr[5] via Rdata_acc port
//      MAC multiply moved to separate mac_unit.sv module
//      Eliminates 8 FFs (~4 ALMs)
//   D. LED register removed: assign LED = Rdata_acc (combinational)
//      Eliminates 8 FFs (~4 ALMs)
//   E. gpr[7] removed: 7-register file [6:0]
//      Eliminates up to 8 FFs
//   F. wave_addr_reg: dedicated external register for %6
//      Resolves write-port conflict in MACI (mac_result→%5 + %6++)
//      +8 FFs but enables MACI without pipeline stall
//
// Instruction format (16-bit):
//   [15:11] opcode(5)  [10:8] %d(3)  [7:5] %s(3)  [4:0] imm5(5)
//
// Register map:
//   %0=0 (write-suppressed)  %1=SW[7:0]  %2=i  %3=SW[8]
//   %4=removed  %5=acc/LED  %6=wave_addr (external reg)
//
// Author: ar7n25
//-----------------------------------------------------
`include "alucodes.sv"
`include "opcodes.sv"

module picoMIPS (
    input  logic        clk,
    input  logic [9:0]  SW,
    output logic [7:0]  LED
);

localparam Psize = 4;    // 4-bit PC — 16 slots
localparam Isize = 15;   // 16-bit instruction
localparam n     = 8;

logic reset;
assign reset = ~SW[9];

// Instruction fields
logic [Isize:0] I;
logic [4:0]     opcode;
logic [2:0]     Raddr_d, Raddr_s;
logic [4:0]     imm5;

assign opcode  = I[15:11];
assign Raddr_d = I[10:8];
assign Raddr_s = I[7:5];
assign imm5    = I[4:0];

// PC
logic [Psize-1:0] PCout;
logic PCincr, PCrelbranch;

// Decoder outputs
logic [2:0] ALUfunc;
logic       imm_sel, w, mac_en, mac_incr, use_mac_result;

// Z flag
logic flags, flags_comb;

// Register file outputs
logic [n-1:0] Rdata1_rf, Rdata2, Rdata1, Wdata;
logic [n-1:0] Rdata_acc;  // direct read of gpr[5]
logic [2:0]   Waddr;

// MAC always writes to %5
assign Waddr = mac_en ? 3'd5 : Raddr_d;

// ALU B-input
logic [n-1:0] Alub, alu_result;
assign Alub = imm_sel ? {3'b0, imm5} : Rdata2;

// ── Dedicated wave address register (%6) ─────────────────────────────────
// Kept outside regs.sv to resolve MACI write-port conflict:
// MACI needs to write mac_result→gpr[5] AND increment wave_addr
// in the same clock cycle. Dedicated register solves this cleanly.
logic [n-1:0] wave_addr_reg;

always_ff @(posedge clk or posedge reset) begin
    if (reset)
        wave_addr_reg <= 8'b0;
    else if (mac_incr)
        wave_addr_reg <= wave_addr_reg + 8'd1;  // MACI: auto-increment
    else if (w && Raddr_d == 3'd6)
        wave_addr_reg <= Wdata;                  // SUBI/ADDI writes %6
end

// Wave ROM addressed by wave_addr_reg
logic [n-1:0] wave_data;

// MAC unit — instantiated as separate module (DSP inferred)
logic [n-1:0] mac_result;

// Writeback
assign Wdata = use_mac_result ? mac_result : alu_result;

// ── LED combinational from gpr[5] (opt D: no LED register) ───────────────
assign LED = Rdata_acc;

// ── Module instantiations ─────────────────────────────────────────────────
pc #(.Psize(Psize)) u_pc (
    .clk(clk), 
    .reset(reset),
    .PCincr(PCincr), 
    .PCrelbranch(PCrelbranch),
    .Branchaddr(imm5[Psize-1:0]),
    .PCout(PCout)
);

prog #(.Psize(Psize), .Isize(Isize)) u_prog (
    .address(PCout), .I(I)
);

decoder u_dec (
    .opcode(opcode), 
    .flags(flags),
    .PCincr(PCincr), 
    .PCrelbranch(PCrelbranch),
    .ALUfunc(ALUfunc), 
    .imm(imm_sel),
    .w(w), 
    .mac_en(mac_en), 
    .mac_incr(mac_incr),
    .use_mac_result(use_mac_result)
);

regs #(.n(n)) u_regs (
    .clk(clk), 
    .reset(reset), 
    .w(w), 
    .Wdata(Wdata),
    .Raddr1(Raddr_s), 
    .Raddr2(Raddr_d), 
    .Waddr(Waddr),
    .Rdata1(Rdata1_rf), 
    .Rdata2(Rdata2),
    .Rdata_acc(Rdata_acc)
);

alu #(.n(n)) u_alu (
    .a(Rdata1), 
    .b(Alub),
    .func(ALUfunc), 
    .flags(flags_comb), 
    .result(alu_result)
);

wave_rom u_wrom (
    .addr(wave_addr_reg),
    .data(wave_data)
);

mac_unit #(.n(n)) u_mac (
    .wave_data (wave_data),
    .kernel    (imm5),
    .acc       (Rdata_acc),
    .result    (mac_result)
);

// ── SW input injection ────────────────────────────────────────────────────
always_comb begin
    case (Raddr_s)
        3'd1:    Rdata1 = SW[7:0];
        3'd3:    Rdata1 = {7'b0, SW[8]};
        default: Rdata1 = Rdata1_rf;
    endcase
end

// ── Registered Z flag ─────────────────────────────────────────────────────
always_ff @(posedge clk or posedge reset)
    if (reset) flags <= 1'b0;
    else        flags <= flags_comb;

endmodule