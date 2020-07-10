
   /*
    *
    */

module multiplier(
    input wire ck,
    input wire [15:0] a,
    input wire [15:0] b,
    output reg [31:0] out
);

    reg [31:0] result;

    always @(negedge ck) begin
        result <= a * b;
        out <= result;
    end

endmodule


