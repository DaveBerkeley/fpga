
module i2s_rx(
    input wire ck,
    input wire en, // I2S sck en
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

parameter EOW = 18;
parameter WORD_LEN = 32;

always @(posedge ck) begin

    if (en) begin

        shift <= { shift[14:0], sd };

        if (frame_posn == EOW)
            left <= shift;

        if (frame_posn == (EOW+WORD_LEN))
            right <= shift;

    end

end

endmodule

