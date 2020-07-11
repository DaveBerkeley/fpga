
module i2s_clock
# (parameter DIVIDER=12)
(
    input wire ck,      // 12MHz system clock
    output reg sck,     // I2S clock
    output reg ws,      // I2S WS
    output reg [5:0] frame_posn // 64 clock counter for complete L/R frame
);

    // Divide the 12MHz system clock down
    localparam BITS = $clog2(DIVIDER);
    reg [BITS:0] prescale = 0;

    // 64 clock counter for complete L/R frame
    initial frame_posn = 0;

    always @(posedge ck) begin

        if (prescale == (DIVIDER-1)) begin
            prescale <= 0;
            frame_posn <= frame_posn + 1;
        end else begin
            prescale <= prescale + 1;
        end

        sck <= (prescale >= (DIVIDER/2)) ? 1 : 0;
        ws <= (frame_posn >= 32) ? 1 : 0;

    end

endmodule

