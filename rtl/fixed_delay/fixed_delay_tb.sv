`timescale 1ns / 1ps

// Self-checking testbench for the fixed_delay shift-register module.
//
// fixed_delay presents data_i on data_o after Delay *enabled* clock cycles.
// Disabled cycles freeze the pipeline, and reset clears every stage to zero.
//
// Verification strategy:
//   * Directed tests independently exercise the three interesting behaviors:
//     latency (a marker propagates after exactly Delay enabled cycles),
//     enable gating (disabled cycles must not advance the pipeline), and
//     reset (clears all stages).
//   * A behavioral reference model reimplements the pipeline and drives a
//     scoreboard that compares data_o against it every cycle under randomized
//     stimulus.
//
// Concurrent SystemVerilog assertions are unsupported by Verilator (as of
// 2026-06), so checking is done procedurally against the reference model.

module fixed_delay_tb;
  localparam int Delay = 4;
  localparam int DWidth = 32;
  localparam int ClkPeriod = 10;  // 100 MHz

  logic clk;
  logic rst;
  logic en;
  logic [DWidth-1:0] data_i;
  logic [DWidth-1:0] data_o;

  fixed_delay #(
    .Delay  (Delay),
    .DWidth (DWidth)
  ) uut (
    .clk_i  (clk),
    .rst_i  (rst),
    .en_i   (en),
    .data_i (data_i),
    .data_o (data_o)
  );

  initial clk = 0;
  always #(ClkPeriod / 2.0) clk = ~clk;

  // Dump a waveform only when launched with +dump=1 (see verilator_harness_pkg).
  initial verilator_harness_pkg::dump_waves();

  // --- Reference model -------------------------------------------------------
  // model[i] mirrors the DUT's internal pipeline stage i for i in 1..Delay.
  logic [DWidth-1:0] model[1:Delay];
  wire  [DWidth-1:0] expected = model[Delay];

  always_ff @(posedge clk) begin
    if (rst) begin
      for (int i = 1; i <= Delay; i++) model[i] <= '0;
    end else if (en) begin
      model[1] <= data_i;
      for (int i = 2; i <= Delay; i++) model[i] <= model[i-1];
    end
  end

  // --- Test bookkeeping ------------------------------------------------------
  int errors = 0;

  // Present inputs for the upcoming clock edge. Driving on the negedge keeps
  // them stable across the posedge that both the DUT and the model sample.
  task automatic drive(input logic en_v, input logic [DWidth-1:0] d);
    @(negedge clk);
    en     = en_v;
    data_i = d;
  endtask

  task automatic expect_out(input logic [DWidth-1:0] exp, input string msg);
    if (data_o !== exp) begin
      $error("%s @%0t: data_o=0x%08h expected=0x%08h", msg, $time, data_o, exp);
      errors++;
    end
  endtask

  task automatic scoreboard(input string msg);
    if (data_o !== expected) begin
      $error("%s @%0t: data_o=0x%08h model=0x%08h", msg, $time, data_o, expected);
      errors++;
    end
  endtask

  task automatic apply_reset(input int cycles);
    en     = 1'b0;
    data_i = '0;
    rst    = 1'b1;
    repeat (cycles) @(negedge clk);
    rst = 1'b0;
  endtask

  // --- Stimulus --------------------------------------------------------------
  initial begin
    logic [DWidth-1:0] marker;

    en     = 1'b0;
    data_i = '0;
    rst    = 1'b1;

    // 1) Reset clears the pipeline; the output must be zero.
    apply_reset(Delay + 2);
    expect_out('0, "after reset");

    // 2) Latency: a marker appears at the output exactly Delay enabled cycles
    //    after it is presented, and the output stays zero until then.
    marker = 32'hDEAD_BEEF;
    drive(1'b1, marker);
    for (int i = 1; i < Delay; i++) begin
      drive(1'b1, '0);
      expect_out('0, $sformatf("latency: premature output at stage %0d", i));
    end
    drive(1'b1, '0);
    expect_out(marker, "latency: marker at output");
    drive(1'b1, '0);
    expect_out('0, "latency: output drained");

    // 3) Enable gating: disabled cycles must freeze the pipeline, so the marker
    //    only advances on enabled cycles regardless of data_i.
    apply_reset(Delay + 2);
    marker = 32'h1234_5678;
    drive(1'b1, marker);
    repeat (5) begin
      drive(1'b0, 32'hFFFF_FFFF);
      expect_out('0, "gating: output changed while disabled");
    end
    for (int i = 1; i < Delay; i++) begin
      drive(1'b1, '0);
      expect_out('0, $sformatf("gating: premature output at stage %0d", i));
    end
    drive(1'b1, '0);
    expect_out(marker, "gating: marker at output after re-enable");

    // 4) Randomized stimulus checked against the reference model.
    apply_reset(Delay + 2);
    for (int i = 0; i < 500; i++) begin
      drive(($urandom_range(0, 1) != 0), $urandom);
      scoreboard("random");
    end

    // 5) Mid-stream reset clears all stages while data is in flight.
    drive(1'b1, 32'hA5A5_A5A5);
    drive(1'b1, 32'h5A5A_5A5A);
    @(negedge clk);
    rst = 1'b1;
    @(negedge clk);
    expect_out('0, "mid-stream reset");
    rst = 1'b0;

    if (errors != 0) $fatal(1, "fixed_delay_tb FAILED with %0d error(s)", errors);

    $display("fixed_delay_tb PASSED (Delay=%0d, DWidth=%0d)", Delay, DWidth);
    $finish;
  end

endmodule
