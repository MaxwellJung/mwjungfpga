module vga_controller #(
  parameter int unsigned COLOR_DEPTH = 4
) (
  input logic clk_i,
  input logic rst_i,

  output logic h_sync_o,
  output logic v_sync_o,
  output logic [COLOR_DEPTH-1:0] red_o,
  output logic [COLOR_DEPTH-1:0] green_o,
  output logic [COLOR_DEPTH-1:0] blue_o
);

  logic h_sync;
  logic v_sync;

  logic [$clog2(400*300)-1:0] pixel_index;
  logic pixel_index_valid;

  vga_timing_generator vga_timing_generator_inst (
    .clk_i (clk_i),
    .rst_i (rst_i),

    .h_sync_o (h_sync),
    .v_sync_o (v_sync),

    .pixel_index_o       (pixel_index),
    .pixel_index_valid_o (pixel_index_valid)
  );

  assign {h_sync_o, v_sync_o} = {h_sync, v_sync};
  assign {red_o, green_o, blue_o} = pixel_index_valid ? 3*COLOR_DEPTH'(pixel_index) : '0;

endmodule
