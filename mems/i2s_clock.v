
module I2S_CLOCK(
    input wire sys_ck,  // 12MHz system clock
    output wire sck,    // I2S clock
    output wire ws,     // I2S WS
    output reg [5:0] bit_count // 64 clock counter for complete L/R frame
);

// Divide the 12MHz system clock down 
// To 3MHz
reg [1:0] prescale = 0;

// 64 clock counter for complete L/R frame
initial bit_count = 0;

always @(posedge sys_ck) begin
    if (prescale == 3) begin
        prescale <= 0;
        bit_count <= bit_count + 1;
    end else begin
        prescale <= prescale + 1;
    end
end

assign sck = (prescale >= 2)   ? 1 : 0;
assign ws  = (bit_count >= 32) ? 1 : 0;

endmodule

