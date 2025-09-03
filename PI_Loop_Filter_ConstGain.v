`timescale 1ns / 1ps
module Loop_Filter_PI #(
    parameter DATA_WIDTH   = 16,    // Input error bit width (Q1.15)
    parameter COEFF_WIDTH  = 16,    // Coefficient width (Q1.15)
    parameter ACC_WIDTH    = 32     // Accumulator width
)(
    input  wire                         clk,
    input  wire                         rst,
    input  wire                         zs_valid,           // Valid from Zero Stuffer
    input  wire signed [DATA_WIDTH-1:0] e_k_zs,             // Q1.15 timing error
    output reg  signed [DATA_WIDTH-1:0] v_k                 // Q1.15 control signal
);
    // === Tuned Gains for QPSK ===
    // K1 ? 0.0078125  ? 2??
    // K2 ? 0.00012207 ? 2?¹³
    localparam signed [COEFF_WIDTH-1:0] K1 = 16'sh0020;  // +0.0078125
    localparam signed [COEFF_WIDTH-1:0] K2 = 16'sh0004;  // +0.00012207
    reg signed [ACC_WIDTH-1:0] integrator_accum;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            integrator_accum <= 0;
            v_k              <= 0;
        end else begin
            if (zs_valid) begin
                // Update integrator and filter output
                integrator_accum <= integrator_accum + (e_k_zs * K2);
                v_k <= ((e_k_zs * K1) + integrator_accum) >>> 15;
            end else begin
                // Hold previous value
                v_k <= v_k;
            end
        end
    end
endmodule



