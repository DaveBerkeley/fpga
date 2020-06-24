
module I2S_CLOCK(
    input wire ck,      // 12MHz system clock
    output reg sck,     // I2S clock
    output reg ws,      // I2S WS
    output reg [5:0] frame_posn, // 64 clock counter for complete L/R frame
    output reg [3:0] prescale
);

// Divide the 12MHz system clock down to 1MHz
initial prescale = 0;

// 64 clock counter for complete L/R frame
initial frame_posn = 0;

always @(posedge ck) begin

    if (prescale == 3) begin
        prescale <= 0;
        frame_posn <= frame_posn + 1;
    end else begin
        prescale <= prescale + 1;
    end

    if (prescale >= 2)
        sck <= 1;
    else
        sck <= 0;

    if (frame_posn >= 32)
        ws <= 1;
    else
        ws <= 0;
end

endmodule

