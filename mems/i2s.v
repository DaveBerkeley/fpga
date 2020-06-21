
module I2S_IN(sys_ck, sck, ws, sdi, data_out, do_left, do_right);

input sys_ck; // system clock

// I2S signals :
output sck, ws;
input sdi;

// Output latch and signals
output [15:0] data_out;
output do_left;
output do_right;

// Divide the 12MHz system clock down :
reg [3:0] prescale = 0;
// 64 clock counter for complete L/R frame
reg [5:0] bit_count = 0;

always @(posedge sys_ck) begin
    if (prescale == 11) begin
        prescale <= 0;
        bit_count <= bit_count + 1;
    end else begin
        prescale <= prescale + 1;
    end
end

parameter EOW = 17;
parameter WORD_LEN = 32;

assign sck = (prescale>=6)          ? 1 : 0;
assign ws  = (bit_count>=WORD_LEN)  ? 1 : 0;

// 24-bit data into 16-bit shift register. Shift in sd on posedge of sck

reg [15:0] shift = 0;

always @(posedge sck) begin
    shift <= (shift << 1) + sdi;
end

assign do_left  = sck | ((bit_count == EOW) ? 0 : 1);
assign do_right = sck | ((bit_count == (EOW+WORD_LEN)) ? 0 : 1);

assign data_out = (do_left | do_right) ? 16'hzzzz : shift;

endmodule

