
`default_nettype none

module top (
    input wire clk,
    output wire r,
    output wire g,
    output wire b
);

    reg [25:0] divider = 0;

    always @(posedge clk) begin
        divider <= divider + 1;
    end

    assign r = divider[20];
    assign g = divider[21];
    assign b = divider[22];

endmodule

