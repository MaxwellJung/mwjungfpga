`timescale 1ns / 1ps
`default_nettype none

// Top-level VGA design for the Nexys A7-100T (xc7a100tcsg324-1).
//
// Drives an 800x600@60Hz VGA signal on the board's VGA connector. The 800x600
// mode uses a 40 MHz pixel clock, which is synthesized from the 100 MHz board
// clock by an MMCM inside clock_generator (VCO = 100 MHz * 10 = 1000 MHz,
// 1000 MHz / 25 = 40 MHz). The vga_controller runs entirely in the 40 MHz
// pixel-clock domain.
module vga_top #(
  parameter int unsigned COLOR_DEPTH = 4  // Nexys A7 VGA DAC is 4 bits/channel
) (
  input  wire clk_i,   // 100 MHz board clock
  input  wire rstn_i,  // active-low reset (CPU reset button)

  output wire                   vga_hs_o,
  output wire                   vga_vs_o,
  output wire [COLOR_DEPTH-1:0] vga_r_o,
  output wire [COLOR_DEPTH-1:0] vga_g_o,
  output wire [COLOR_DEPTH-1:0] vga_b_o
);

  wire pixel_clk;     // 40 MHz VGA pixel clock
  wire pixel_locked;  // asserted once pixel_clk is stable

  clock_generator #(
    .PRIM_TYPE       ("MMCM"),
    .CLKIN_PERIOD_NS (10.0),   // 100 MHz reference
    .CLKFB_MULT      (10.0),   // VCO = 1000 MHz
    .DIVCLK_DIVIDE   (1),
    .CLKOUT0_DIVIDE  (25.0),   // 1000 MHz / 25 = 40 MHz
    .CLKOUT0_DUTY    (0.5),
    .CLKOUT0_PHASE   (0.0)
  ) pixel_clk_gen (
    .clk_i    (clk_i),
    .rst_i    (~rstn_i),
    .clk_o    (pixel_clk),
    .locked_o (pixel_locked)
  );

  // Hold the controller in reset until the pixel clock has locked.
  wire pixel_rst = ~rstn_i | ~pixel_locked;

  vga_controller #(
    .COLOR_DEPTH (COLOR_DEPTH)
  ) vga_controller_inst (
    .clk_i (pixel_clk),
    .rst_i (pixel_rst),

    .h_sync_o (vga_hs_o),
    .v_sync_o (vga_vs_o),
    .red_o    (vga_r_o),
    .green_o  (vga_g_o),
    .blue_o   (vga_b_o)
  );

endmodule
`default_nettype wire
