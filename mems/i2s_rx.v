
module I2S_RX(
    input wire sck, // I2S sck
    input wire ws,  // I2S ws
    input wire [5:0] frame_posn,
    input wire sd,  // I2S data in
    output reg [15:0] left, 
    output reg [15:0] right
);

// The 24-bit data from the mic, starts at t=2 (I2S spec)
// Only use the first 16-bits, the trailing bits are noise.

initial left = 0;
initial right = 0;

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

    if (frame_posn == EOW)
        left <= shift;

    if (frame_posn == (EOW+WORD_LEN))
        right <= shift;

end

endmodule

