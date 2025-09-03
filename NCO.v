`timescale 1ns / 1ps
module NCO_Update_Mu #(
    parameter MU_WIDTH = 10,        // Q1.9
    parameter MU_FRAC  = 9
)(
    input  wire                      clk,
    input  wire                      rst,
    input  wire signed [15:0]        v_k_in,      // From loop filter (Q1.15)
    output reg  [MU_WIDTH-1:0]       mu,          // Q1.9 (unsigned)
    output reg                       underflow
);
    // Constants
    localparam signed [MU_WIDTH-1:0] HALF = 10'sd256; // 0.5
    localparam        [MU_WIDTH-1:0] ONE  = 10'd512;  // 1.0
    // Convert Q1.15 ? Q1.9
    wire signed [MU_WIDTH-1:0] v_k_scaled = v_k_in >>> (15 - MU_FRAC);  // shift by 6
    // 1-bit wider accumulator for overflow check
    reg signed [MU_WIDTH:0] mu_sum;
    always @(posedge clk or posedge rst) begin
    if (rst) begin
        mu         <= 10'd154;  // 0.3
        underflow  <= 1'b0;
        mu_sum     <= 0;
    end else begin
        mu_sum <= $signed({1'b0, mu}) + HALF + v_k_scaled;
        if (mu_sum >= ONE) begin
            mu        <= mu_sum - ONE;
            underflow <= 1'b1;
        end else begin
            mu        <= mu_sum[MU_WIDTH-1:0];
            underflow <= 1'b0;
        end
    end
end
endmodule
