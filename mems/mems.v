
module top (input CLK, output P1A1, output P1A2, input P1A3, input P1A4);

// Generate i2S clock and word select signals

wire i2s_sck, i2s_ws;
// i2s_bit_count tracks the position in the 64-bit L/R frame.
wire [5:0] i2s_bit_count;

I2S_CLOCK i2s_ck(CLK, i2s_sck, i2s_ws, i2s_bit_count);

// Acquire pairs of I2S streams

reg [15:0] mic_0_l;
reg [15:0] mic_0_r;
wire sd_0;

I2S_IN i2s_0(i2s_sck, i2s_ws, i2s_bit_count, sd_0, mic_0_l, mic_0_r);

reg [15:0] mic_1_l;
reg [15:0] mic_1_r;
wire sd_1;

I2S_IN i2s_1(i2s_sck, i2s_ws, i2s_bit_count, sd_1, mic_1_l, mic_1_r);

// TODO : clock the L/R data into RAM
// TODO : sum the data with delays
// TODO : write the data to the DAC

// Assign the IO

assign P1A1 = i2s_sck;
assign P1A2 = i2s_ws;
assign P1A3 = sd_0;
assign P1A4 = sd_1;

endmodule

