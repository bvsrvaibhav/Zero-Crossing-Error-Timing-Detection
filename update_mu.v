`timescale 1ns / 1ps

module QPSK_Symbol_Timing_Sync_Top #(
    parameter DATA_WIDTH   = 16,   // e.g., Q1.15
    parameter MU_WIDTH     = 10,   // Q1.9 for ?
    parameter MU_FRAC      = 9,
    parameter COEFF_WIDTH  = 16,   // Loop filter gain width
    parameter ACC_WIDTH    = 32    // Loop filter integrator width
)(
    input  wire                         clk,
    input  wire                         rst,
    input  wire signed [DATA_WIDTH-1:0] I_in,
    input  wire signed [DATA_WIDTH-1:0] Q_in,
    output reg  signed [DATA_WIDTH-1:0] I_out,
    output reg  signed [DATA_WIDTH-1:0] Q_out,
    output reg                          valid_out  // Asserted only when I/Q out is valid
);
    // Internal Signals
    wire signed [DATA_WIDTH-1:0] I_interp, Q_interp;
    wire                          interp_valid;
    wire signed [DATA_WIDTH-1:0] e_k;
    wire                          zcted_valid;
    wire signed [DATA_WIDTH-1:0] e_k_zs;
    wire                          zs_valid;
    wire signed [15:0]           v_k;
    wire [MU_WIDTH-1:0]          mu;
    wire                          underflow;
    // Add this wire to gate interpolator output to ZCTED
    wire signed [DATA_WIDTH-1:0] I_interp_zcted = interp_valid ? I_interp : 0;
    // Cleaner gated error for Zero_Stuffer
    wire signed [DATA_WIDTH-1:0] e_k_gated = (zcted_valid && underflow) ? e_k : 0;
    // === Interpolator ===
    Piecewise_Parabolic_Interpolator #(
        .DATA_WIDTH(DATA_WIDTH),
        .MU_WIDTH(MU_WIDTH),
        .MU_FRAC(MU_FRAC)
    ) interpolator_inst (
        .clk(clk),
        .rst(rst),
        .I_in(I_in),
        .Q_in(Q_in),
        .mu(mu),
        .I_interp(I_interp),
        .Q_interp(Q_interp),
        .valid_out(interp_valid)
    );
    // === ZCTED ===
    ZCTED #(
        .DATA_WIDTH(DATA_WIDTH)
    ) zcted_inst (
        .clk(clk),
        .rst(rst),
        .valid_in(interp_valid),
        .I_interp(I_interp_zcted),
        .e_k(e_k),
        .zcted_valid(zcted_valid)
    );
    // === Zero Stuffer ===
    Zero_Stuffer #(
        .DATA_WIDTH(DATA_WIDTH)
    ) zs_inst (
        .clk(clk),
        .rst(rst),
        .e_k(e_k_gated),
        .underflow(underflow),
        .e_k_zs(e_k_zs),
        .zs_valid(zs_valid)
    );
    // === Loop Filter ===
    Loop_Filter_PI #(
        .DATA_WIDTH(DATA_WIDTH),
        .COEFF_WIDTH(COEFF_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) loop_filter_inst (
        .clk(clk),
        .rst(rst),
        .zs_valid(zs_valid),
        .e_k_zs(e_k_zs),
        .v_k(v_k)
    );
    // === NCO + Update Mu ===
    NCO_Update_Mu #(
        .MU_WIDTH(MU_WIDTH),
        .MU_FRAC(MU_FRAC)
    ) nco_update_inst (
        .clk(clk),
        .rst(rst),
        .v_k_in(v_k),         // Q1.15 ? internally scaled to Q1.9
        .mu(mu),
        .underflow(underflow)
    );
// Internal holding registers
reg signed [DATA_WIDTH-1:0] I_out_reg, Q_out_reg;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        I_out_reg <= 0;
        Q_out_reg <= 0;
        valid_out <= 0;
    end else if (underflow) begin
        // Correct: Update when underflow == 1
        I_out_reg <= I_interp;
        Q_out_reg <= Q_interp;
        valid_out <= 1'b1;
    end else begin
        // Hold values, don't change them
        valid_out <= 1'b0;
    end
end
// Assign output ports from holding registers
always @(*) begin
    I_out = I_out_reg;
    Q_out = Q_out_reg;
end
endmodule
