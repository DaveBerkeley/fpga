
module top (input CLK, output P1A1, output P1A2, input P1A3);

// Generate i2S clock and word select symbols

wire sck, ws;
// bit_count tracks the position in the 64-bit L/R frame.
wire [5:0] bit_count;

I2S_CLOCK i2s_ck(CLK, sck, ws, bit_count);

// Acquire a pair of I2S streams

reg [15:0] mic_0;
reg [15:0] mic_1;
wire sd_0;

I2S_IN i2s_0(sck, ws, bit_count, sd_0, mic_0, mic_1);

// Assign the IO

assign P1A1 = sck;
assign P1A2 = ws;
assign P1A3 = sd_0;

endmodule

