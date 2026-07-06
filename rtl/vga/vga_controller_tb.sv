`timescale 1ns / 1ps

// Basic testbench for vga_controller.
//
// Drives clock and reset and runs the VGA pipeline for three full frames,
// dumps a VCD, and performs light sanity checks:
//   * no output is unknown (X/Z) after reset,
//   * h_sync_o produces genuine sync pulses (goes high, then low again), and
//   * three vertical frames elapse (counted via v_sync_o pulses).
//
// Frames are measured between consecutive v_sync_o pulses, so the run length
// tracks the timing generator automatically instead of a hardcoded cycle count.

module vga_controller_tb;
  localparam int unsigned ColorDepth = 4;
  localparam int ClkPeriod = 10;          // 100 MHz
  localparam int unsigned FramesToRun = 3;
  // Safety watchdog: ~6 frames of an 800x600 (1056x628) timing, so a stuck
  // pipeline fails fast instead of hanging.
  localparam int MaxCycles = 4_000_000;

  logic clk;
  logic rst;

  logic h_sync;
  logic v_sync;
  logic [ColorDepth-1:0] red;
  logic [ColorDepth-1:0] green;
  logic [ColorDepth-1:0] blue;

  vga_controller #(
    .COLOR_DEPTH (ColorDepth)
  ) dut (
    .clk_i    (clk),
    .rst_i    (rst),
    .h_sync_o (h_sync),
    .v_sync_o (v_sync),
    .red_o    (red),
    .green_o  (green),
    .blue_o   (blue)
  );

  initial clk = 0;
  always #(ClkPeriod / 2.0) clk = ~clk;

  // Dump a waveform only when launched with +dump=1 (see verilator_harness_pkg).
  initial verilator_harness_pkg::dump_waves();

  int errors = 0;
  bit hsync_high_seen = 1'b0;
  bit sync_pulse_seen = 1'b0;

  task automatic check_known(input string msg);
    if ($isunknown({h_sync, v_sync, red, green, blue})) begin
      $error("%s @%0t: unknown output (h=%b v=%b r=0x%0h g=0x%0h b=0x%0h)",
             msg, $time, h_sync, v_sync, red, green, blue);
      errors++;
    end
  endtask

  initial begin
    int cycles;
    int frames;
    bit started;
    logic v_sync_prev;

    rst = 1'b1;
    repeat (5) @(negedge clk);
    rst = 1'b0;

    cycles      = 0;
    frames      = 0;
    started     = 1'b0;
    v_sync_prev = v_sync;

    // Count FramesToRun frame periods, where each period is the span between
    // consecutive v_sync_o pulses (falling edges). The first falling edge is
    // the reference boundary; the next FramesToRun edges bound whole frames.
    while (frames < FramesToRun) begin
      @(negedge clk);
      cycles++;
      check_known("run");

      if (h_sync) hsync_high_seen = 1'b1;
      else if (hsync_high_seen) sync_pulse_seen = 1'b1;  // low after high => real pulse

      if (v_sync_prev && !v_sync) begin
        if (!started) started = 1'b1;  // first boundary: start counting
        else frames++;
      end
      v_sync_prev = v_sync;

      if (cycles > MaxCycles)
        $fatal(1, "watchdog: only %0d frame(s) after %0d cycles", frames, cycles);
    end

    if (!hsync_high_seen) begin
      $error("h_sync_o never went high; horizontal timing not running");
      errors++;
    end
    if (!sync_pulse_seen) begin
      $error("h_sync_o never pulsed low after going high; no sync pulse observed");
      errors++;
    end

    if (errors != 0) $fatal(1, "vga_controller_tb FAILED with %0d error(s)", errors);

    $display("vga_controller_tb PASSED (%0d frames, %0d cycles)", frames, cycles);
    $finish;
  end

endmodule
