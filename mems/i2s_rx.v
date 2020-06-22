
module I2S_RX(
    input wire sck, // I2S sck
    input wire ws,  // I2S ws
    input wire [5:0] bit_count, // position in frame
    input wire sd,  // I2S data in
    output reg [15:0] out_l, 
    output reg [15:0] out_r
);

// The 24-bit data from the mic, starts at t=2 (I2S spec)
// Only use the first 16-bits, the trailing bits are noise.

// shift the microphone data into 16-bit shift register. 
reg [15:0] shift = 0;

always @(posedge sck) begin
    shift <= (shift << 1) + sd;
end

// copy the shift-register state to the Left/Right latches
// at the end of the 16 significant bits.

parameter EOW = 17;
parameter WORD_LEN = 32;

always @(negedge sck) begin

    if (bit_count == EOW)
        out_l <= shift;

    if (bit_count == (EOW+WORD_LEN))
        out_r <= shift;

end

endmodule

