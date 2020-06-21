
module I2S_CLOCK(sys_ck, sck, ws, bit_count);

input sys_ck; // 12MHz system clock

// I2S signals :
output sck, ws;
// 64 clock counter for complete L/R frame
output reg [5:0] bit_count = 0;

// Divide the 12MHz system clock down :
reg [3:0] prescale = 0;

always @(posedge sys_ck) begin
    if (prescale == 11) begin
        prescale <= 0;
        bit_count <= bit_count + 1;
    end else begin
        prescale <= prescale + 1;
    end
end

// parameter EOW = 17;
parameter WORD_LEN = 32;

assign sck = (prescale>=6)          ? 1 : 0;
assign ws  = (bit_count>=WORD_LEN)  ? 1 : 0;

endmodule

