`timescale 1ns / 1ps
`default_nettype none

module fixed_delay #(
  parameter int Delay = 4,
  parameter int DWidth = 32
) (
  input wire clk_i,
  input wire rst_i,
  input wire en_i,

  input  wire  [DWidth-1:0] data_i,
  output logic [DWidth-1:0] data_o
);

  logic [Delay:0][DWidth-1:0] pipeline;

  assign pipeline[0] = data_i;

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      pipeline[Delay:1] <= '0;
    end else if (en_i) begin
      pipeline[Delay:1] <= pipeline[Delay-1:0];
    end
  end

  assign data_o = pipeline[Delay];

endmodule
`default_nettype wire
