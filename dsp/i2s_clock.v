
module i2s_clock
# (parameter DIVIDER=12, BITS=$clog2(DIVIDER))
(
    input wire ck,  // system clock
    input wire rst, // system reset
    output reg en,  // I2S enable
    output reg sck, // I2S clock
    output reg ws,  // I2S WS
    output reg [5:0] frame_posn // 64 clock counter for complete L/R frame
);

    // Divide the system clock down
    reg [BITS:0] prescale = 0;

    // 64 clock counter for complete L/R frame
    initial begin
        frame_posn = 0;
        en = 0;
        ws = 0;
        sck = 0;
    end

    always @(posedge ck) begin

        if (rst) begin

            prescale <= 0;
            frame_posn <= 0;
            en <= 0;
            ws <= 0;
            sck <= 0;

        end else begin

            if (prescale == (DIVIDER-1)) begin
                prescale <= 0;
                frame_posn <= frame_posn + 1;
                en <= 1;
            end else begin
                prescale <= prescale + 1;
                en <= 0;
            end

        end

        sck <= (prescale >= (DIVIDER/2)) ? 1 : 0;
        ws <= (frame_posn >= 32) ? 1 : 0;

    end

endmodule

