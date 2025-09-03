`timescale 1ns / 1ps
module Piecewise_Parabolic_Interpolator #(  
    parameter DATA_WIDTH = 16,
    parameter MU_WIDTH   = 10,  // Q1.9 signed
    parameter MU_FRAC    = 9
)(
    input  wire                         clk,
    input  wire                         rst,
    input  wire signed [DATA_WIDTH-1:0] I_in,
    input  wire signed [DATA_WIDTH-1:0] Q_in,
    input  wire signed [MU_WIDTH-1:0]   mu,  // from NCO
    output reg  signed [DATA_WIDTH-1:0] I_interp,
    output reg  signed [DATA_WIDTH-1:0] Q_interp,
    output reg                          valid_out  // HIGH when interpolated output is valid
);
    // Constants
    localparam signed [15:0] ALPHA = 16'sh4000;  // 0.5 in Q1.15 (alpha)
    localparam signed [15:0] BETA  = 16'sh4000;  // 1 - alpha = 0.5 (beta)
    // Sample delay buffers: x[n-2] ? x[n+1] = [0] to [3]
    reg signed [DATA_WIDTH-1:0] I_reg [0:3];
    reg signed [DATA_WIDTH-1:0] Q_reg [0:3];
    // Warm-up counter to know when delay buffers are ready
    reg [1:0] warmup_counter;
    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 4; i = i + 1) begin
                I_reg[i] <= 0;
                Q_reg[i] <= 0;
            end
            warmup_counter <= 0;
            valid_out <= 0;
        end else begin
            // Shift in new samples
            I_reg[0] <= I_reg[1];
            I_reg[1] <= I_reg[2];
            I_reg[2] <= I_reg[3];
            I_reg[3] <= I_in;
            Q_reg[0] <= Q_reg[1];
            Q_reg[1] <= Q_reg[2];
            Q_reg[2] <= Q_reg[3];
            Q_reg[3] <= Q_in;
            // Warm-up valid flag
            if (warmup_counter < 3)
                warmup_counter <= warmup_counter + 1;
            valid_out <= (warmup_counter >= 3);
        end
    end
    // ? and ?^2
    wire signed [15:0] mu_frac = mu;  // Assume input is already Q1.9
    wire signed [31:0] mu_sq   = (mu_frac * mu_frac) >>> MU_FRAC;  // Q2.18
    // Interpolation for I
    wire signed [31:0] p21_I = ((I_reg[2] - I_reg[0]) * ALPHA) >>> 15;
    wire signed [31:0] p22_I = ((I_reg[3] - I_reg[1]) * BETA)  >>> 15;
    wire signed [31:0] parab_I = (mu_sq * (p21_I + p22_I)) >>> MU_FRAC;
    wire signed [31:0] linear_I = ((mu_frac * (I_reg[2] - I_reg[1])) >>> (MU_FRAC + 1));
    wire signed [31:0] interp_sum_I = parab_I + linear_I + (I_reg[2] <<< 15);
    // Interpolation for Q
    wire signed [31:0] p21_Q = ((Q_reg[2] - Q_reg[0]) * ALPHA) >>> 15;
    wire signed [31:0] p22_Q = ((Q_reg[3] - Q_reg[1]) * BETA)  >>> 15;
    wire signed [31:0] parab_Q = (mu_sq * (p21_Q + p22_Q)) >>> MU_FRAC;
    wire signed [31:0] linear_Q = ((mu_frac * (Q_reg[2] - Q_reg[1])) >>> (MU_FRAC + 1));
    wire signed [31:0] interp_sum_Q = parab_Q + linear_Q + (Q_reg[2] <<< 15);
    // Final output: Q1.15 truncation (no rounding)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            I_interp <= 0;
            Q_interp <= 0;
        end else begin
            I_interp <= interp_sum_I[30:15];
            Q_interp <= interp_sum_Q[30:15];
        end
    end
endmodule




