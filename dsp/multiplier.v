
   /*
    *
    */

module multiplier(
    input wire ck,
    input  wire /*signed*/ [15:0] a,
    input wire /*signed*/ [15:0] b,
    output reg /*signed*/ [31:0] out
);

    always @(negedge ck) begin
        out <= a * b;
    end

endmodule


