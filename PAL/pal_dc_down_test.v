`timescale 1ns / 1ps

module pal_dc_down_test;

    localparam DATA_WIDTH      = 12;
    localparam DATA_RATE_HZ    = 15360000;

    localparam real CLK_PERIOD_NS = 1e9 / DATA_RATE_HZ;

    reg                         clk;
    reg                         reset_n;
    reg  signed [DATA_WIDTH-1:0] data_in;
    wire        [DATA_WIDTH-1:0] data_out;

    localparam integer NUM_SAMPLES = 21000; //335872 всего в файле
    reg  signed [15:0] mem16 [0:NUM_SAMPLES-1];

    integer i;

    pal_dc_down #(
        .DATA_WIDTH     (DATA_WIDTH),
        .DATA_RATE_HZ   (DATA_RATE_HZ)
    ) dut0 (
        .clk      (clk),
        .reset_n  (reset_n),
        .data_in  (data_in),
        .data_out (data_out)
    );

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD_NS/2.0) clk = ~clk;
    end

    initial begin
        reset_n = 1'b0;
        data_in = '0;

        $readmemh("PAL_15.36MSPS_video_frames.hex", mem16);

        $dumpfile("pal_dc_down_test.vcd");
        $dumpvars(0, pal_dc_down_test);

        #(10*CLK_PERIOD_NS);
        reset_n = 1'b1;

        // подаем выборку за выборкой
        for (i = 0; i < NUM_SAMPLES; i = i + 1) begin
            // обрезка 16‑битного signed до 12‑битного signed:
            // берем старшие 12 бит, тк исходный код - 16‑битный доп код
            data_in = mem16[i][15 -: DATA_WIDTH];

            #(CLK_PERIOD_NS);  // ждем один такт
        end

        #(100*CLK_PERIOD_NS);

        $finish;
    end

endmodule
