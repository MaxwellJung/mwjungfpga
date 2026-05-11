`timescale 1ns / 1ps
`default_nettype none

module counter #(
    parameter int CountBits = 8
) (
    input wire clk_in,
    input wire rst_in,

    input wire en_in,

    output logic [CountBits-1:0] count_out
);

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            count_out <= 0;
        end else if (en_in) begin
            count_out <= count_out + 1;
        end
    end

endmodule
`default_nettype wire
