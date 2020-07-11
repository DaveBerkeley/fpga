
   /*
    *   Generate frame_posn bit index from I2S sck and ws signals
    */

module i2s_secondary (
    input wire sck,
    input wire ws,
    output reg [5:0] frame_posn
);

    initial frame_posn = 0;

    reg prev_ws = 0;

    always @(negedge sck) begin
        prev_ws <= ws;

        if (prev_ws && !ws)
            frame_posn <= 1;
        else
            frame_posn <= frame_posn + 1;
    end

endmodule


