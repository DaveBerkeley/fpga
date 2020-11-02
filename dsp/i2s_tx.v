
module i2s_tx
    #(parameter CLOCKS=64)
    (input wire ck,
    input wire en,
    input wire [5:0] frame_posn,
    input wire [15:0] left,
    input wire [15:0] right,
    output reg sd   // data out
);

    reg [15:0] shift = 0;
    wire [5:0] MASK;
    wire [5:0] frame;

    assign MASK = 6'((1 << $clog2(CLOCKS)) - 1);
    assign frame = frame_posn & MASK;

    always @(posedge ck) begin

        if (en) begin
            sd <= shift[15];

            if (frame == 0) begin
                shift <= left;
            end else if (frame == 6'(CLOCKS/2)) begin
                shift <= right;
            end else begin
                shift <= shift << 1;
            end

        end

    end

endmodule

