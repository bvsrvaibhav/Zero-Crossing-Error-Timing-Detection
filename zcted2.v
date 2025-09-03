`timescale 1ns / 1ps
module ZCTED #(
    parameter DATA_WIDTH = 16
)(
    input  wire                         clk,
    input  wire                         rst,
    input  wire                         valid_in,      // Comes from interpolator.valid_out
    input  wire signed [DATA_WIDTH-1:0] I_interp,      // Real part from interpolator
    output reg  signed [DATA_WIDTH-1:0] e_k,           // Timing error output
    output reg                          zcted_valid    // Valid after 2-cycle delay filled
);
    // Delay registers
    reg signed [DATA_WIDTH-1:0] I_d1, I_d2;
    // Sign computation
    wire signed [1:0] sgn_I_now = (I_interp > 0) ? 2'sd1 :
                                  (I_interp < 0) ? -2'sd1 : 2'sd0;
    wire signed [1:0] sgn_I_d2  = (I_d2 > 0) ? 2'sd1 :
                                  (I_d2 < 0) ? -2'sd1 : 2'sd0;
    // Timing error calculation: e(k) = I[n-1] * (sgn(I[n]) - sgn(I[n-2]))
    wire signed [DATA_WIDTH-1:0] mult_error = I_d1 * (sgn_I_now - sgn_I_d2);
    // Internal valid pipeline counter
    reg [1:0] valid_count;
    // Main process
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            I_d1         <= 0;
            I_d2         <= 0;
            e_k          <= 0;
            zcted_valid  <= 0;
            valid_count  <= 0;
        end else if (valid_in) begin
            // Advance delay line only on valid interpolated input
            I_d2 <= I_d1;
            I_d1 <= I_interp;
            // Compute ZCTED error
            e_k  <= mult_error;
            // Generate valid output after 2 samples
            if (valid_count < 2)
                valid_count <= valid_count + 1;
            zcted_valid <= (valid_count >= 2);
        end
    end
endmodule





