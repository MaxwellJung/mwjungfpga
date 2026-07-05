`timescale 1ns / 1ps

package verilator_harness_pkg;
  import "DPI-C" function string sv_getenv(input string env_name);

  string output_dir = sv_getenv("TEST_UNDECLARED_OUTPUTS_DIR");

endpackage
