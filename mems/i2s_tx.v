
module i2s_tx(
    input wire sck, // I2S sck
    input wire [5:0] frame_posn,
    input wire [15:0] left,
    input wire [15:0] right,
    output reg sd   // data out
);

reg [15:0] shift = 0;

//  Shift the data out on every negedge of sck

always @(negedge sck) begin

    sd <= shift[15];

    case (frame_posn)
        0       : shift <= left;
        32      : shift <= right;
        default : shift <= shift << 1;
    endcase

end

endmodule

