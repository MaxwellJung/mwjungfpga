`timescale 1ns / 1ps

module counter_tb ();
    localparam int NumBits = 8;
    localparam int ClkPeriod = 10; // 100 MHz clock

    logic clk;
    logic rst;
    logic en;
    wire [NumBits-1:0] count;

    counter #(
        .CountBits(NumBits)
    ) counter_inst (
        .clk_in (clk),
        .rst_in (rst),
        .en_in  (en),
        .count_out (count)
    );

    initial clk = 0;
    always #(ClkPeriod / 2.0)
        clk = ~clk;

    initial begin
        $dumpfile("counter_tb.vcd");
        $dumpvars(0, counter_tb);
    end

    initial begin
        // pause counter
        en = 0;

        // hold rst for 10 clock cycles
        rst = 1;
        repeat (10) @(posedge clk);
        rst = 0;


        // start counter for 50 ns
        repeat (10) @(posedge clk);
        en = 1;
        repeat (5) @(posedge clk);
        en = 0;

        assert (count != 0)
            else $error("Counter should not be zero after rst is deasserted");

        // resume counter for 50 ns
        repeat (10) @(posedge clk);
        en = 1;
        repeat (5) @(posedge clk);
        en = 0;

        // hold rst for 50 ns
        rst = 1;
        repeat (5) @(posedge clk);
        rst = 0;

        repeat (20) @(posedge clk);
        $finish;
    end

endmodule
