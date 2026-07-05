`timescale 1ns / 1ps

import verilator_harness_pkg::output_dir;

module fixed_delay_tb;
  localparam int Delay = 4;
  localparam int DWidth = 32;
  localparam int ClkPeriod = 10ns; // 100 MHz clock

  // UUT Instantiation.
  logic clk;
  logic rst;
  logic en;

  logic [DWidth-1:0] data_i;
  logic [DWidth-1:0] data_o;

  fixed_delay #(
    .Delay  (Delay),
    .DWidth (DWidth)
  ) uut (
    .clk_i (clk),
    .rst_i (rst),
    .en_i  (en),

    .data_i (data_i),
    .data_o (data_o)
  );

  initial clk = '0;
  always begin
    #(ClkPeriod / 2.0) clk = ~clk;
  end

  always @(posedge clk) begin
    if (rst) begin
      data_i <= '0;
    end else begin
      data_i <= $urandom;
    end
  end

  initial begin
    $dumpfile({output_dir, "/fixed_delay_tb.vcd"});
    $dumpvars(0, fixed_delay_tb);
  end

  always begin
    // hold rst for 10 clock cycles.
    @(posedge clk);
    rst <= '1;
    repeat(10) @(posedge clk);
    rst <= '0;

    // wait 5 clock cycles.
    repeat(5) @(posedge clk);

    en <= '1;

    // wait 20 clock cycles.
    repeat(20) @(posedge clk);
    $finish;
  end

  // Below concurrent assertion is unsupported by verilator as of 2026-06,
  // but should work in other simulators.
  // assert property (
  //   @(posedge clk) disable iff (rst)
  //   en |->
  //     ##Delay data_o == $past(data_i, Delay)
  // ) else $error("data_o should be equal to data_i delayed by %0d cycles", Delay);

endmodule
