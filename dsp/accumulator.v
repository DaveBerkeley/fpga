
   /*
    *
    */

module accumulator(
    input wire ck,
    input wire en,
    input wire rst,
    input wire add,
    input wire [31:0] in,
    output reg signed [(OUT_W-1):0] out
);

    parameter OUT_W = 40;

    initial out = 0;

    wire [(OUT_W-33):0] zeros;
    wire [(OUT_W-1):0] to_add;

    assign zeros = 0;
    assign to_add = { zeros, in };

    wire [(OUT_W-1):0] prev;

    assign prev = rst ? 0 : out;

    always @(negedge ck) begin
        if (en) begin
            if (add)
                out <= prev + to_add;
            else
                out <= prev - to_add;
        end
    end

endmodule


