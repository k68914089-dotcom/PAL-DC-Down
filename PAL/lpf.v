module lpf #(
    parameter   DATA_WIDTH      = 12,
    parameter   DATA_RATE_HZ    = 15360000,
    parameter   CUTOFF_FREQ_HZ  = 1000000
)(
    input                       clk, //15.36 МГц - данные поступают на каждый такт
    input                       reset_n,

    input   signed  [DATA_WIDTH-1:0]    data_in,
    output  signed  [DATA_WIDTH-1:0]    data_out
);

// реализация ФНЧ через скользящее среднее (простейший случай)
// 1. примерно берем порядок фильтра исходя из частоты дискретизации и частоты среза
// примерно по формуле N = 0.443 * f_s / f_c 
localparam [31:0] N = 443 * (DATA_RATE_HZ / CUTOFF_FREQ_HZ) / 1000 + 1;

// 2. объявление регистров
reg [DATA_WIDTH-1:0]            shift_reg   [0:N-1];
reg [DATA_WIDTH+$clog2(N)-1:0]  sum;

// 3. логика скользящего среднего
integer j;
always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        sum <= 0;
        for (j = 0; j < N; j = j + 1)
            shift_reg[j] <= 0;
    end else begin
        shift_reg[0] <= data_in;
        for (j = 1; j < N; j = j + 1)
            shift_reg[j] <= shift_reg[j-1];

        sum <= $signed(sum) + $signed(data_in) - $signed(shift_reg[0]);
    end
end

wire signed [DATA_WIDTH+$clog2(N)-1:0] avg = $signed(sum) / $signed(N); // TODO
assign data_out = avg[DATA_WIDTH-1:0];

endmodule