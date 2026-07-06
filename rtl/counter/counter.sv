`timescale 1ns / 1ps
`default_nettype none

module counter #(
  parameter int unsigned INITIAL_COUNT = 0,
  parameter int unsigned MAX_COUNT = 32'hFFFF_FFFF,
  localparam int NumBits = $clog2(MAX_COUNT + 1)
) (
  input wire clk_i,
  input wire rst_i,
  input wire en_i,

  output logic [NumBits-1:0] count_o
);

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      count_o <= INITIAL_COUNT;
    end else if (en_i) begin
      count_o <= (count_o == MAX_COUNT) ? INITIAL_COUNT : count_o + 1;
    end
  end

endmodule
`default_nettype wire
