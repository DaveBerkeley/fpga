
module top (input CLK, output P1A1, output P1A2, input P1A3, input P1A4);

// Generate i2S clock and word select signals

wire i2s_sck, i2s_ws;
// i2s_bit_count tracks the position in the 64-bit L/R frame.
wire [5:0] i2s_bit_count;

I2S_CLOCK i2s_ck(CLK, i2s_sck, i2s_ws, i2s_bit_count);

// Acquire pairs of I2S streams

wire sd_0;
reg [15:0] mic_0;
reg [15:0] mic_1;

I2S_IN i2s_0(i2s_sck, i2s_ws, i2s_bit_count, sd_0, mic_0, mic_1);

wire sd_1;
reg [15:0] mic_2;
reg [15:0] mic_3;

I2S_IN i2s_1(i2s_sck, i2s_ws, i2s_bit_count, sd_1, mic_2, mic_3);

// clock the microphone data into RAM

reg [6:0] ram_idx = 0;

// in-pointer incremented every frame
always @(negedge i2s_ws) begin
    # 1 ram_idx <= ram_idx + 1;
end

parameter OFFSET_0 = 5;
parameter OFFSET_1 = 30;
parameter OFFSET_2 = 70;
parameter OFFSET_3 = 100;

wire [15:0] mic_delay_0;
wire [15:0] mic_delay_1;
wire [15:0] mic_delay_2;
wire [15:0] mic_delay_3;

DELAY delay_0(i2s_ws, mic_0, ram_idx, OFFSET_0, mic_delay_0);
DELAY delay_1(i2s_ws, mic_1, ram_idx, OFFSET_1, mic_delay_1);
DELAY delay_2(i2s_ws, mic_2, ram_idx, OFFSET_2, mic_delay_2);
DELAY delay_3(i2s_ws, mic_3, ram_idx, OFFSET_3, mic_delay_3);

// sum the delayed data

reg [15:0] audio;

always @(posedge i2s_ws) begin
    audio <= (mic_0 + mic_1 + mic_2 + mic_3) >> 2;
end

// TODO : write the data to the DAC

// Assign the IO

assign P1A1 = i2s_sck;
assign P1A2 = i2s_ws;
assign P1A3 = sd_0;
assign P1A4 = sd_1;

endmodule

