
module top (input CLK, output P1A1, output P1A2, input P1A3, input P1A4, input P1A7, output P1A8);

// Generate i2S clock and word select signals

wire i2s_sck, i2s_ws;
// i2s_bit_count tracks the position in the 64-bit L/R frame.
wire [5:0] i2s_bit_count;

I2S_CLOCK i2s_ck(.sys_ck(CLK), .sck(i2s_sck), .ws(i2s_ws), .bit_count(i2s_bit_count));

// Acquire pairs of I2S streams

wire sd_0;
wire [15:0] mic_0;
wire [15:0] mic_1;

I2S_RX i2s_0(.sck(i2s_sck), .ws(i2s_ws), .bit_count(i2s_bit_count), .sd(sd_0), .out_l(mic_0), .out_r(mic_1));

wire sd_1;
wire [15:0] mic_2;
wire [15:0] mic_3;

I2S_RX i2s_1(.sck(i2s_sck), .ws(i2s_ws), .bit_count(i2s_bit_count), .sd(sd_1), .out_l(mic_2), .out_r(mic_3));

wire sd_2;
wire [15:0] mic_4;
wire [15:0] mic_5;

I2S_RX i2s_2(.sck(i2s_sck), .ws(i2s_ws), .bit_count(i2s_bit_count), .sd(sd_2), .out_l(mic_4), .out_r(mic_5));

// TODO write the microphone data into RAM

// TODO Read out delayed samples from RAM

// write the data to the DAC

wire i2s_out;

I2S_TX i2s_tx(.sck(i2s_sck), .ws(i2s_ws), .data_l(mic_0), .data_r(mic_1), .data_out(i2s_out));

// Assign the IO

assign P1A1 = i2s_sck;
assign P1A2 = i2s_ws;
assign sd_0 = P1A3;
assign sd_1 = P1A4;
assign sd_2 = P1A7;
assign P1A8 = i2s_out;

endmodule

