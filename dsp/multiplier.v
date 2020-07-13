
   /*
    *
    */

module multiplier(
    input wire ck,
    input wire [15:0] a,
    input wire [15:0] b,
    output reg [31:0] out
);

    always @(posedge ck) begin
        out <= a * b;
    end

endmodule


