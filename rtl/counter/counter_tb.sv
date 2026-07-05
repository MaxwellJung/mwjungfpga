`timescale 1ns / 1ps

import sim_lib_pkg::output_dir;

module counter_tb;
  localparam int InitialCount = 3;
  localparam int MaxCount = 7;
  localparam int NumBits = $clog2(MaxCount + 1);
  localparam int ClkPeriod = 10;

  logic clk;
  logic rst;
  logic en;
  logic [NumBits-1:0] count;

  counter #(
    .InitialCount (InitialCount),
    .MaxCount     (MaxCount)
  ) dut (
    .clk_i   (clk),
    .rst_i   (rst),
    .en_i    (en),
    .count_o (count)
  );

  initial clk = 0;
  always #(ClkPeriod / 2.0) clk = ~clk;

  initial begin
    $dumpfile({output_dir, "/counter_tb.vcd"});
    $dumpvars(0, counter_tb);
  end

  task automatic wait_cycles(input int n);
    repeat (n) @(posedge clk);
  endtask

  task automatic apply_reset(input int cycles = 2);
    rst = 1;
    en = 0;
    wait_cycles(cycles);
    rst = 0;
    @(posedge clk);
  endtask

  task automatic check_count(input int expected, input string msg);
    assert (count == expected)
      else $error("%s: expected %0d, got %0d", msg, expected, count);
  endtask

  initial begin
    rst = 1;
    en = 0;

    apply_reset(3);
    check_count(InitialCount, "after reset");

    // Counter holds when enable is low.
    wait_cycles(5);
    check_count(InitialCount, "while disabled");

    // Count five enabled cycles: 3 -> 4 -> 5 -> 6 -> 7.
    en = 1;
    wait_cycles(4);
    en = 0;
    check_count(MaxCount, "after counting to max");

    // Wrap to InitialCount on the next enabled cycle.
    en = 1;
    @(posedge clk);
    en = 0;
    check_count(InitialCount, "after wrap at max");

    // Resume counting from the wrapped value.
    en = 1;
    wait_cycles(2);
    en = 0;
    check_count(InitialCount + 2, "after two more enabled cycles");

    // Reset clears an in-progress count.
    en = 1;
    wait_cycles(3);
    apply_reset(2);
    check_count(InitialCount, "after mid-count reset");

    $finish;
  end

endmodule
