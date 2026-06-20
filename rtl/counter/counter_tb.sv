`timescale 1ns / 1ps

// Import the C library function
import sim_lib_pkg::output_dir;

module counter_tb;
  localparam int NumBits = 8;
  localparam int ClkPeriod = 10; // 100 MHz clock

  logic clk;
  logic rst;
  logic en;
  wire [NumBits-1:0] count;

  counter #(
    .NumBits (NumBits)
  ) counter_inst (
    .clk_i (clk),
    .rst_i (rst),
    .en_i  (en),
    .count_o (count)
  );

  initial clk = 0;
  always #(ClkPeriod / 2.0)
    clk = ~clk;

  initial begin
    $dumpfile({output_dir, "/counter_tb.vcd"});
    $dumpvars(0, counter_tb);
  end

  initial begin
    // pause counter
    en = 0;

    // hold rst for 10 clock cycles
    rst = 1;
    repeat (10) @(posedge clk);
    rst = 0;

    // Wait for 10 clock cycles.
    repeat (10) @(posedge clk);

    assert (count == 0)
      else $error("Counter should be zero after reset");

    // start counter for 50 ns
    @(posedge clk);
    en = 1;
    repeat (5) @(posedge clk);
    en = 0;

    assert (count == 5)
      else $error("Counter should be 5 after counting for 5 clock cycles");

    // resume counter for 120 ns
    @(posedge clk);
    en = 1;
    repeat (12) @(posedge clk);
    en = 0;

    assert (count == 17)
      else $error("Counter should be 17 after counting for 12 more clock cycles");

    repeat (20) @(posedge clk);

    assert (count == 17)
      else $error("Counter should remain at 17 when disabled");
    $finish;
  end

endmodule
