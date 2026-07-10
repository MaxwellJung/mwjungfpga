`timescale 1ns / 1ps
`default_nettype none

module vga_timing_generator #(
  parameter int unsigned H_VIS_AREA_PXL    = 800,
  parameter int unsigned H_FRONT_PORCH_PXL = 40,
  parameter int unsigned H_SYNC_PULSE_PXL  = 128,
  parameter int unsigned H_BACK_PORCH_PXL  = 88,

  parameter int unsigned V_VIS_AREA_PXL    = 600,
  parameter int unsigned V_FRONT_PORCH_PXL = 1,
  parameter int unsigned V_SYNC_PULSE_PXL  = 4,
  parameter int unsigned V_BACK_PORCH_PXL  = 23,

  // Sync pulse polarity: 1 = positive (active-high) pulse, 0 = negative
  // (active-low). VESA 800x600@60 uses positive sync on both; 640x480@60
  // uses negative sync on both.
  parameter bit H_SYNC_POLARITY = 1'b1,
  parameter bit V_SYNC_POLARITY = 1'b1,

  parameter int unsigned DOWNSCALE = 2,

  localparam int unsigned HPxlCount = H_VIS_AREA_PXL + H_FRONT_PORCH_PXL + H_SYNC_PULSE_PXL + H_BACK_PORCH_PXL,
  localparam int unsigned VPxlCount = V_VIS_AREA_PXL + V_FRONT_PORCH_PXL + V_SYNC_PULSE_PXL + V_BACK_PORCH_PXL,
  localparam int unsigned PixelCount = (H_VIS_AREA_PXL/DOWNSCALE)*(V_VIS_AREA_PXL/DOWNSCALE)
) (
  input logic clk_i,
  input logic rst_i,

  output logic h_sync_o,
  output logic v_sync_o,

  output logic [$clog2(PixelCount)-1:0] pixel_index_o,
  output logic                          pixel_index_valid_o
);

  logic [$clog2(HPxlCount)-1:0] h_pxl_index;
  logic [$clog2(VPxlCount)-1:0] v_pxl_index;

  logic h_in_sync_pulse;
  logic v_in_sync_pulse;

  counter #(
    .MAX_COUNT(HPxlCount-1)
  ) counter_inst_0 (
    .clk_i (clk_i),
    .rst_i (rst_i),
    .en_i  (1'b1),
    .count_o (h_pxl_index)
  );

  counter #(
    .MAX_COUNT(VPxlCount-1)
  ) counter_inst_1 (
    .clk_i (clk_i),
    .rst_i (rst_i),
    .en_i  (h_pxl_index == HPxlCount-1),
    .count_o (v_pxl_index)
  );

  // Assert during the sync-pulse window (front porch elapsed, back porch not
  // yet reached). Polarity is applied when registering the sync outputs.
  always_comb begin
    h_in_sync_pulse = ((H_VIS_AREA_PXL + H_FRONT_PORCH_PXL) <= h_pxl_index)
                   && (h_pxl_index < (H_VIS_AREA_PXL + H_FRONT_PORCH_PXL + H_SYNC_PULSE_PXL));
    v_in_sync_pulse = ((V_VIS_AREA_PXL + V_FRONT_PORCH_PXL) <= v_pxl_index)
                   && (v_pxl_index < (V_VIS_AREA_PXL + V_FRONT_PORCH_PXL + V_SYNC_PULSE_PXL));
  end

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      // Reset to the inactive (non-pulse) level for the selected polarity.
      h_sync_o <= ~H_SYNC_POLARITY;
      v_sync_o <= ~V_SYNC_POLARITY;

      pixel_index_o       <= 0;
      pixel_index_valid_o <= 0;
    end else begin
      h_sync_o <= H_SYNC_POLARITY ? h_in_sync_pulse : ~h_in_sync_pulse;
      v_sync_o <= V_SYNC_POLARITY ? v_in_sync_pulse : ~v_in_sync_pulse;

      pixel_index_o <= (H_VIS_AREA_PXL >> $clog2(DOWNSCALE))
                       * (v_pxl_index >> $clog2(DOWNSCALE))
                       + (h_pxl_index >> $clog2(DOWNSCALE));
      pixel_index_valid_o <= (h_pxl_index < H_VIS_AREA_PXL) && (v_pxl_index < V_VIS_AREA_PXL);
    end
  end

endmodule
`default_nettype wire
