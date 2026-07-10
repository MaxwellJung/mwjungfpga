`timescale 1ns / 1ps
`default_nettype none

// Parameterizable single-output clock generator for AMD/Xilinx 7-series
// (Artix-7) devices. Selects between the MMCM (MMCME2_BASE) and the PLL
// (PLLE2_BASE) clock-management primitives via the PRIM_TYPE parameter.
//
// Output frequency:
//   f_clk_o = f_clk_i * CLKFB_MULT / (DIVCLK_DIVIDE * CLKOUT0_DIVIDE)
//
// Constraints imposed by the primitives (see UG472/DS181):
//   * MMCM: CLKFB_MULT 2.000-64.000, CLKOUT0_DIVIDE 1.000-128.000 (fractional),
//           DIVCLK_DIVIDE 1-106.
//   * PLL : CLKFB_MULT 2-64, CLKOUT0_DIVIDE 1-128 (integer only; fractional
//           values are truncated), DIVCLK_DIVIDE 1-56.
//   * The VCO frequency f_clk_i * CLKFB_MULT / DIVCLK_DIVIDE must stay within
//     the device/speed-grade range.
//
// rst_i is active-high (wired directly to the primitive RST). locked_o
// deasserts during reset/re-lock and asserts once the output clock is stable.
//
// Note: this module instantiates Xilinx UNISIM primitives, so it is intended
// for Vivado synthesis. Simulating it requires the UNISIM library (it is not
// Verilator-friendly without primitive models).
module clock_generator #(
  parameter      PRIM_TYPE       = "MMCM",  // "MMCM" or "PLL"
  parameter real CLKIN_PERIOD_NS = 10.0,    // reference clock period (10 ns = 100 MHz)
  parameter real CLKFB_MULT      = 10.0,    // VCO feedback multiply
  parameter int  DIVCLK_DIVIDE   = 1,       // VCO input divide
  parameter real CLKOUT0_DIVIDE  = 10.0,    // output-0 divide
  parameter real CLKOUT0_DUTY    = 0.5,     // output-0 duty cycle (0.01-0.99)
  parameter real CLKOUT0_PHASE   = 0.0      // output-0 phase offset (degrees)
) (
  input  wire clk_i,     // reference clock in
  input  wire rst_i,     // active-high reset
  output wire clk_o,     // generated clock (global-buffer driven)
  output wire locked_o   // asserted when clk_o is stable
);

  wire clk_fb;    // feedback path (internal, unbuffered)
  wire clk_out0;  // primitive clock output (unbuffered)

  generate
    if (PRIM_TYPE == "MMCM") begin : g_mmcm
      MMCME2_BASE #(
        .BANDWIDTH          ("OPTIMIZED"),
        .CLKIN1_PERIOD      (CLKIN_PERIOD_NS),
        .DIVCLK_DIVIDE      (DIVCLK_DIVIDE),
        .CLKFBOUT_MULT_F    (CLKFB_MULT),
        .CLKFBOUT_PHASE     (0.0),
        .CLKOUT0_DIVIDE_F   (CLKOUT0_DIVIDE),
        .CLKOUT0_DUTY_CYCLE (CLKOUT0_DUTY),
        .CLKOUT0_PHASE      (CLKOUT0_PHASE),
        .STARTUP_WAIT       ("FALSE")
      ) u_mmcm (
        .CLKIN1    (clk_i),
        .CLKFBIN   (clk_fb),
        .CLKFBOUT  (clk_fb),
        .CLKFBOUTB (),
        .CLKOUT0   (clk_out0),
        .CLKOUT0B  (),
        .CLKOUT1   (),
        .CLKOUT1B  (),
        .CLKOUT2   (),
        .CLKOUT2B  (),
        .CLKOUT3   (),
        .CLKOUT3B  (),
        .CLKOUT4   (),
        .CLKOUT5   (),
        .CLKOUT6   (),
        .LOCKED    (locked_o),
        .PWRDWN    (1'b0),
        .RST       (rst_i)
      );
    end else if (PRIM_TYPE == "PLL") begin : g_pll
      PLLE2_BASE #(
        .BANDWIDTH          ("OPTIMIZED"),
        .CLKIN1_PERIOD      (CLKIN_PERIOD_NS),
        .DIVCLK_DIVIDE      (DIVCLK_DIVIDE),
        .CLKFBOUT_MULT      (int'(CLKFB_MULT)),
        .CLKFBOUT_PHASE     (0.0),
        .CLKOUT0_DIVIDE     (int'(CLKOUT0_DIVIDE)),
        .CLKOUT0_DUTY_CYCLE (CLKOUT0_DUTY),
        .CLKOUT0_PHASE      (CLKOUT0_PHASE),
        .STARTUP_WAIT       ("FALSE")
      ) u_pll (
        .CLKIN1   (clk_i),
        .CLKFBIN  (clk_fb),
        .CLKFBOUT (clk_fb),
        .CLKOUT0  (clk_out0),
        .CLKOUT1  (),
        .CLKOUT2  (),
        .CLKOUT3  (),
        .CLKOUT4  (),
        .CLKOUT5  (),
        .LOCKED   (locked_o),
        .PWRDWN   (1'b0),
        .RST      (rst_i)
      );
    end else begin : g_invalid
      $error("clock_generator: PRIM_TYPE must be \"MMCM\" or \"PLL\", got \"%s\"", PRIM_TYPE);
    end
  endgenerate

  // Drive the generated clock onto a global clock buffer.
  BUFG u_clk_bufg (
    .I (clk_out0),
    .O (clk_o)
  );

endmodule
`default_nettype wire
