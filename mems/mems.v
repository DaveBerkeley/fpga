
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

I2S_RX i2s_0(i2s_sck, i2s_ws, i2s_bit_count, sd_0, mic_0, mic_1);

wire sd_1;
reg [15:0] mic_2;
reg [15:0] mic_3;

I2S_RX i2s_1(i2s_sck, i2s_ws, i2s_bit_count, sd_1, mic_2, mic_3);

// clock the microphone data into RAM

reg [6:0] ram_idx = 0;

// in-pointer incremented every frame
always @(negedge i2s_ws) begin
    # 1 ram_idx <= ram_idx + 1;
end

// TODO : write the data to the DAC

// Assign the IO

assign P1A1 = i2s_sck;
assign P1A2 = i2s_ws;
assign P1A3 = sd_0;
assign P1A4 = sd_1;

endmodule

