`timescale 1ns / 1ps

package verilator_harness_pkg;
  import "DPI-C" function string sv_getenv(input string env_name);

  string output_dir = sv_getenv("TEST_UNDECLARED_OUTPUTS_DIR");

  // Dump the whole design to <output_dir>/dump.vcd, but only when the
  // simulation is launched with +dump=1. This keeps `bazel test` fast (no VCD)
  // while `bazel run //rtl/<module>:sim -- --gtkwave` produces a waveform.
  // Call once from an initial block in the testbench top:
  //   initial verilator_harness_pkg::dump_waves();
  task automatic dump_waves();
    int dump_wave = 0;
    if ($value$plusargs("dump=%d", dump_wave) && dump_wave != 0) begin
      $dumpfile({output_dir, "/dump.vcd"});
      $dumpvars(0);
    end
  endtask

endpackage
