
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
    wire [(OUT_W-1):0] in_;

    assign zeros = 0;
    assign in_ = { zeros, in };

    wire [(OUT_W-1):0] prev;

    assign prev = rst ? 0 : out;

    always @(negedge ck) begin
        if (en) begin
            if (add)
                out <= prev + in_;
            else
                out <= prev - in_;
        end
    end

endmodule


