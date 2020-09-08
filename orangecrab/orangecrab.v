
`default_nettype none

module top (
    input wire clk,
    output wire r,
    output wire g,
    output wire b
);

    reg [28:0] divider = 0;

    always @(posedge clk) begin
        divider <= divider + 1;
    end

    assign r = divider[24];
    assign g = divider[25];
    assign b = divider[26];

endmodule

