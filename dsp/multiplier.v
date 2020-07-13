
   /*
    *
    */

module multiplier(
    input wire ck,
    input wire [15:0] a,
    input wire [15:0] b,
    output reg [31:0] out
);

    reg [15:0] in_a;
    reg [15:0] in_b;

    always @(posedge ck) begin
        in_a <= a;
        in_b <= b;
    end

    always @(negedge ck) begin
        out <= in_a * in_b;
    end

endmodule


