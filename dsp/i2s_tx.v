
module i2s_tx(
    input wire ck,
    input wire en,
    input wire [5:0] frame_posn,
    input wire [15:0] left,
    input wire [15:0] right,
    output reg sd   // data out
);

    reg [15:0] shift = 0;

    always @(posedge ck) begin

        if (en) begin
            sd <= shift[15];

            case (frame_posn)
                0       : shift <= left;
                32      : shift <= right;
                default : shift <= shift << 1;
            endcase
        end

    end

endmodule

