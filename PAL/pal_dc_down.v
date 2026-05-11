module pal_dc_down #(
    parameter   DATA_WIDTH      = 12,
    parameter   DATA_RATE_HZ    = 15360000
)(
    input   clk,
    input   reset_n, // если вы не возражаете, я логику сброса внесу

    input   signed  [DATA_WIDTH-1:0]    data_in,
    output          [DATA_WIDTH-1:0]    data_out
);

localparam  [31:0]  CUTOFF_FREQ_A_HZ    = 5000000;
localparam  [31:0]  CUTOFF_FREQ_B_HZ    = 1000000;

wire signed [DATA_WIDTH-1:0]   filter_out_A;
wire signed [DATA_WIDTH-1:0]   filter_out_B;

// фильтр А
lpf #(
    .DATA_WIDTH(DATA_WIDTH),
    .DATA_RATE_HZ(DATA_RATE_HZ),
    .CUTOFF_FREQ_HZ(CUTOFF_FREQ_A_HZ)
) lpf_A (
    .clk(clk),
    .reset_n(reset_n),
    .data_in(data_in),
    .data_out(filter_out_A)
);

// фильтр В
lpf #(
    .DATA_WIDTH(DATA_WIDTH),
    .DATA_RATE_HZ(DATA_RATE_HZ),
    .CUTOFF_FREQ_HZ(CUTOFF_FREQ_B_HZ)
) lpf_B (
    .clk(clk),
    .reset_n(reset_n),
    .data_in(data_in),
    .data_out(filter_out_B)
);

// предельные значения
localparam  signed  [DATA_WIDTH-1:0]    CLAMP_MIN   = -(1 << (DATA_WIDTH-1));
localparam  signed  [DATA_WIDTH-1:0]    CLAMP_MAX   = (1 << (DATA_WIDTH-1)) - 1;

reg signed  [DATA_WIDTH-1:0]    output_value;
reg signed  [DATA_WIDTH-1:0]    K;
reg signed  [DATA_WIDTH-1:0]    Min;
reg signed  [DATA_WIDTH-1:0]    Ref_level;

// комбинационная логика расчета следующего K
wire signed [DATA_WIDTH:0]      K_eval      = $signed(Ref_level) - $signed(Min);
reg signed  [DATA_WIDTH-1:0]    K_next;

always @* begin
    if (K_eval > CLAMP_MAX)
        K_next = CLAMP_MAX;
    else if (K_eval < CLAMP_MIN)
        K_next = CLAMP_MIN;
    else
        K_next = K_eval[DATA_WIDTH-1:0];
end

// комбинационная логика расчета следующей суммы фильтрованных данных А и К
wire signed [DATA_WIDTH:0]      sum_eval    = $signed(filter_out_A) + $signed(K);
reg signed  [DATA_WIDTH-1:0]    sum_next;

always @* begin
    if (sum_eval > CLAMP_MAX)
        sum_next = CLAMP_MAX;
    else if (sum_eval < CLAMP_MIN)
        sum_next = CLAMP_MIN;
    else
        sum_next = sum_eval[DATA_WIDTH-1:0];
end

// количество тактов в 128 мкс
localparam  [31:0]  us128   = DATA_RATE_HZ * 128 / 1000000; // floor(15.36*1e6 * 128*1e-6) = 1966
reg         [31:0]  N;

// последовательная логика переведенная из псевдокода (надеюсь смысл тут передан верно)
always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        K               <= 0;
        Min             <= CLAMP_MAX;
        Ref_level       <= 100;
        N               <= 0;
        output_value    <= 0;
    end else begin
        if (N == us128) begin
            K   <= K_next;
            Min <= CLAMP_MAX;
            N   <= 0;
        end
        else begin
            K   <= K;
            Min <= (filter_out_B < Min) ? filter_out_B : Min;
            N   <= N + 1;
        end

        output_value <= sum_next;
    end
end

// нормализация данных и вывод
assign  data_out    = output_value + CLAMP_MAX;

endmodule