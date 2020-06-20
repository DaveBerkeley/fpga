
module i2s_in(sys_ck, sck, ws, sd);

input sys_ck; // system clock

// I2S signals :
output sck, ws;
input sd;

// Divide the 12MHz system clock down :

reg [3:0] prescale = 0;

always @(posedge sys_ck) begin
    if (prescale >= 12) begin
        prescale <= 0;
    end else begin
        prescale <= prescale + 1;
    end
end

assign sck = (prescale>=6) ? 1 : 0;

// 64 clock counter for complete L/R frame

reg [5:0] bit_count = 0;

always @(negedge sck) begin
    bit_count <= bit_count + 1;
end

assign ws = (bit_count>=32) ? 1 : 0;

// TODO : shift in sd on posedge of sck

endmodule

