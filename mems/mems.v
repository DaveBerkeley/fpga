
module top (input CLK, output P1A1, output P1A2, input P1A3, input P1A4, input P1A7, output P1A8);

// Generate i2S clock and word select signals

wire i2s_sck, i2s_ws;
// frame_posn tracks the position in the 64-bit L/R frame.
wire [5:0] frame_posn;
wire [7:0] frame;

I2S_CLOCK i2s_ck(.ck(CLK), .sck(i2s_sck), .ws(i2s_ws), .frame_posn(frame_posn), .frame(frame));

// Acquire multiple I2S streams

wire sd_0;
wire [15:0] mic_0;
wire [15:0] mic_1;

I2S_RX i2s_0(.sck(i2s_sck), .ws(i2s_ws), .frame_posn(frame_posn), .sd(sd_0), .left(mic_0), .right(mic_1));

wire sd_1;
wire [15:0] mic_2;
wire [15:0] mic_3;

I2S_RX i2s_1(.sck(i2s_sck), .ws(i2s_ws), .frame_posn(frame_posn), .sd(sd_1), .left(mic_2), .right(mic_3));

wire sd_2;
wire [15:0] mic_4;
wire [15:0] mic_5;

I2S_RX i2s_2(.sck(i2s_sck), .ws(i2s_ws), .frame_posn(frame_posn), .sd(sd_2), .left(mic_4), .right(mic_5));

// TODO write the microphone data into RAM

// TODO Read out delayed samples from RAM


// TODO Add the samples together, with a gain factor

// write the data to the I2S DAC

wire i2s_out;

I2S_TX i2s_tx(.sck(i2s_sck), .ws(i2s_ws), .frame_posn(frame_posn), .left(mic_0), .right(mic_1), .sd(i2s_out));

// Assign the IO

assign P1A1 = i2s_sck;
assign P1A2 = i2s_ws;
assign sd_0 = P1A3;
assign sd_1 = P1A4;
assign sd_2 = P1A7;
assign P1A8 = i2s_out;

endmodule

