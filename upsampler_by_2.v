`timescale 1ns / 1ps
module Zero_Stuffer #(
    parameter DATA_WIDTH = 16
)(
    input  wire                         clk,
    input  wire                         rst,
    input  wire signed [DATA_WIDTH-1:0] e_k,        // From ZCTED
    input  wire                         underflow,  // From NCO
    output reg  signed [DATA_WIDTH-1:0] e_k_zs,     // Zero-stuffed output
    output reg                          zs_valid    // Valid flag (only when underflow is 1)
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            e_k_zs   <= 0;
            zs_valid <= 0;
        end else begin
            if (underflow) begin
                e_k_zs   <= e_k;
                zs_valid <= 1;
            end else begin
                e_k_zs   <= 0;
                zs_valid <= e_k_zs;
            end
        end
    end
endmodule







