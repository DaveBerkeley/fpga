
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
    wire [5:0] midpoint;
    wire [5:0] frame;

    generate
        if (CLOCKS==64) begin
            assign MASK = 6'b111111;
            assign midpoint = 32;
        end
        if (CLOCKS==32) begin
            assign MASK = 6'b011111;
            assign midpoint = 16;
        end
    endgenerate

    //assign MASK = 6'b011111; // 6'((1 << $clog2(CLOCKS)) - 1);
    assign frame = frame_posn & MASK;

    always @(posedge ck) begin

        if (en) begin
            sd <= shift[15];

            if (frame == 0) begin
                shift <= left;
            end else if (frame == midpoint) begin
                shift <= right;
            end else begin
                shift <= shift << 1;
            end

        end

    end

endmodule

