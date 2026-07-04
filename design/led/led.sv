module led (
  input wire clk_i,
  input wire rstn_i,

  input  wire  [15:0] sw_i,
  output logic [15:0] led_o
);

  localparam int CyclesPerSecond = 100_000_000; // Number of 100MHz clock cycles in 1 second.
  logic [$clog2(CyclesPerSecond)-1:0] count_100mhz;

  // Count from 0 to CyclesPerSecond-1 in a loop.
  counter #(
    .InitialCount (0),
    .MaxCount     (CyclesPerSecond - 1)
  ) counter_100mhz_inst (
    .clk_i (clk_i),
    .rst_i (~rstn_i),
    .en_i  ('1),

    .count_o (count_100mhz)
  );

  // Count up every time count_100mhz reaches CyclesPerSecond-1,
  // effectively counting number of seconds elapsed.
  logic [15:0] count_1hz;
  counter #(
    .InitialCount (0),
    .MaxCount     (2**16 - 1)
  ) counter_1hz_inst (
    .clk_i (clk_i),
    .rst_i (~rstn_i),
    .en_i  (count_100mhz == CyclesPerSecond - 1),

    .count_o (count_1hz)
  );

  assign led_o = count_1hz ^ sw_i;

endmodule
