
module I2S_IN(sck, ws, bit_count, sd, out_l, out_r);

// I2S signals :
input sck, ws;
input [5:0] bit_count;
input sd;

// Output latch
output reg [15:0] out_l;
output reg [15:0] out_r;

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

    if (bit_count == EOW) begin
        out_l <= shift;
    end

    if (bit_count == (EOW+WORD_LEN)) begin
        out_r <= shift;
    end

end

endmodule

