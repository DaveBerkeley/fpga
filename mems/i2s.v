
module I2S_IN(sck, ws, bit_count, sdi, out_l, out_r);

// I2S signals :
input sck, ws;
input [5:0] bit_count;
input sdi;

// Output latch
output reg [15:0] out_l;
output reg [15:0] out_r;

parameter EOW = 17;
parameter WORD_LEN = 32;

// 24-bit data into 16-bit shift register. Shift in sd on posedge of sck

reg [15:0] shift = 0;

always @(posedge sck) begin
    shift <= (shift << 1) + sdi;
end

always @(posedge sck) begin
    if (bit_count == EOW)
        out_l <= shift;        

    if (bit_count == (EOW+WORD_LEN))
        out_r <= shift;        
end

endmodule

