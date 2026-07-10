`timescale 1ns / 1ps
`default_nettype none

// Parameterizable single-output clock generator for AMD/Xilinx 7-series
// (Artix-7) devices using the *advanced* clock-management primitives:
// MMCME2_ADV or PLLE2_ADV, selected via the PRIM_TYPE parameter.
//
// Over the BASE variants (see clock_generator.sv), the ADV primitives expose:
//   * a dynamic reconfiguration port (DRP) to retune the clock at runtime,
//   * two reference clock inputs with runtime select (clkinsel_i), and
//   * dynamic fine phase shift (MMCM only), plus input/feedback stopped status.
//
// Output frequency:
//   f_clk_o = f_ref * CLKFB_MULT / (DIVCLK_DIVIDE * CLKOUT0_DIVIDE)
// where f_ref is the selected reference (clkin1_i when clkinsel_i = 1,
// clkin2_i when clkinsel_i = 0).
//
// PLLE2_ADV has no phase-shift interface, so in "PLL" mode psclk_i/psen_i/
// psincdec_i are ignored and psdone_o is held low.
//
// Note: instantiates Xilinx UNISIM primitives; intended for Vivado synthesis
// (requires the UNISIM library to simulate).
module clock_generator_adv #(
  parameter      PRIM_TYPE        = "MMCM",   // "MMCM" or "PLL"
  parameter real CLKIN1_PERIOD_NS = 10.0,     // clkin1_i period (10 ns = 100 MHz)
  parameter real CLKIN2_PERIOD_NS = 10.0,     // clkin2_i period
  parameter real CLKFB_MULT       = 10.0,     // VCO feedback multiply
  parameter int  DIVCLK_DIVIDE    = 1,        // VCO input divide
  parameter real CLKOUT0_DIVIDE   = 10.0,     // output-0 divide
  parameter real CLKOUT0_DUTY     = 0.5,      // output-0 duty cycle (0.01-0.99)
  parameter real CLKOUT0_PHASE    = 0.0,      // output-0 phase offset (degrees)
  parameter      COMPENSATION     = "ZHOLD"   // feedback compensation mode
) (
  input  wire clkin1_i,        // reference clock 1
  input  wire clkin2_i,        // reference clock 2
  input  wire clkinsel_i,      // 1: select clkin1_i, 0: select clkin2_i
  input  wire rst_i,           // active-high reset
  input  wire pwrdwn_i,        // active-high power down

  // Dynamic reconfiguration port (DRP).
  input  wire        dclk_i,   // DRP clock
  input  wire        den_i,    // DRP enable
  input  wire        dwe_i,    // DRP write enable
  input  wire [6:0]  daddr_i,  // DRP address
  input  wire [15:0] di_i,     // DRP write data
  output wire [15:0] do_o,     // DRP read data
  output wire        drdy_o,   // DRP ready

  // Dynamic phase shift (MMCM only; ignored for PLL).
  input  wire psclk_i,         // phase-shift clock
  input  wire psen_i,          // phase-shift enable
  input  wire psincdec_i,      // 1: increment, 0: decrement
  output wire psdone_o,        // phase-shift done

  output wire clk_o,           // generated clock (global-buffer driven)
  output wire locked_o,        // asserted when clk_o is stable
  output wire clkin_stopped_o, // input clock stopped status
  output wire clkfb_stopped_o  // feedback clock stopped status
);

  wire clk_fb;    // feedback path (internal, unbuffered)
  wire clk_out0;  // primitive clock output (unbuffered)

  generate
    if (PRIM_TYPE == "MMCM") begin : g_mmcm
      MMCME2_ADV #(
        .BANDWIDTH          ("OPTIMIZED"),
        .COMPENSATION       (COMPENSATION),
        .CLKIN1_PERIOD      (CLKIN1_PERIOD_NS),
        .CLKIN2_PERIOD      (CLKIN2_PERIOD_NS),
        .DIVCLK_DIVIDE      (DIVCLK_DIVIDE),
        .CLKFBOUT_MULT_F    (CLKFB_MULT),
        .CLKFBOUT_PHASE     (0.0),
        .CLKOUT0_DIVIDE_F   (CLKOUT0_DIVIDE),
        .CLKOUT0_DUTY_CYCLE (CLKOUT0_DUTY),
        .CLKOUT0_PHASE      (CLKOUT0_PHASE),
        .CLKOUT4_CASCADE    ("FALSE"),
        .STARTUP_WAIT       ("FALSE")
      ) u_mmcm (
        .CLKIN1       (clkin1_i),
        .CLKIN2       (clkin2_i),
        .CLKINSEL     (clkinsel_i),
        .CLKFBIN      (clk_fb),
        .CLKFBOUT     (clk_fb),
        .CLKFBOUTB    (),
        .CLKOUT0      (clk_out0),
        .CLKOUT0B     (),
        .CLKOUT1      (),
        .CLKOUT1B     (),
        .CLKOUT2      (),
        .CLKOUT2B     (),
        .CLKOUT3      (),
        .CLKOUT3B     (),
        .CLKOUT4      (),
        .CLKOUT5      (),
        .CLKOUT6      (),
        .LOCKED       (locked_o),
        .CLKINSTOPPED (clkin_stopped_o),
        .CLKFBSTOPPED (clkfb_stopped_o),
        .PWRDWN       (pwrdwn_i),
        .RST          (rst_i),
        // DRP
        .DCLK         (dclk_i),
        .DEN          (den_i),
        .DWE          (dwe_i),
        .DADDR        (daddr_i),
        .DI           (di_i),
        .DO           (do_o),
        .DRDY         (drdy_o),
        // Dynamic phase shift
        .PSCLK        (psclk_i),
        .PSEN         (psen_i),
        .PSINCDEC     (psincdec_i),
        .PSDONE       (psdone_o)
      );
    end else if (PRIM_TYPE == "PLL") begin : g_pll
      // PLLE2_ADV has no phase-shift interface.
      assign psdone_o = 1'b0;

      PLLE2_ADV #(
        .BANDWIDTH          ("OPTIMIZED"),
        .COMPENSATION       (COMPENSATION),
        .CLKIN1_PERIOD      (CLKIN1_PERIOD_NS),
        .CLKIN2_PERIOD      (CLKIN2_PERIOD_NS),
        .DIVCLK_DIVIDE      (DIVCLK_DIVIDE),
        .CLKFBOUT_MULT      (int'(CLKFB_MULT)),
        .CLKFBOUT_PHASE     (0.0),
        .CLKOUT0_DIVIDE     (int'(CLKOUT0_DIVIDE)),
        .CLKOUT0_DUTY_CYCLE (CLKOUT0_DUTY),
        .CLKOUT0_PHASE      (CLKOUT0_PHASE),
        .STARTUP_WAIT       ("FALSE")
      ) u_pll (
        .CLKIN1       (clkin1_i),
        .CLKIN2       (clkin2_i),
        .CLKINSEL     (clkinsel_i),
        .CLKFBIN      (clk_fb),
        .CLKFBOUT     (clk_fb),
        .CLKOUT0      (clk_out0),
        .CLKOUT1      (),
        .CLKOUT2      (),
        .CLKOUT3      (),
        .CLKOUT4      (),
        .CLKOUT5      (),
        .LOCKED       (locked_o),
        .CLKINSTOPPED (clkin_stopped_o),
        .CLKFBSTOPPED (clkfb_stopped_o),
        .PWRDWN       (pwrdwn_i),
        .RST          (rst_i),
        // DRP
        .DCLK         (dclk_i),
        .DEN          (den_i),
        .DWE          (dwe_i),
        .DADDR        (daddr_i),
        .DI           (di_i),
        .DO           (do_o),
        .DRDY         (drdy_o)
      );
    end else begin : g_invalid
      $error("clock_generator_adv: PRIM_TYPE must be \"MMCM\" or \"PLL\", got \"%s\"", PRIM_TYPE);
    end
  endgenerate

  // Drive the generated clock onto a global clock buffer.
  BUFG u_clk_bufg (
    .I (clk_out0),
    .O (clk_o)
  );

endmodule
`default_nettype wire
