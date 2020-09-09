
`default_nettype none

module top (
    input wire clk,
    output wire r,
    output wire g,
    output wire b,
    output wire p0,
    output wire p1,
    output wire p5,
    output wire p6,
    output wire p9,
    output wire p10,
    output wire p11,
    output wire p12,
    output wire p13
);

    reg [28:0] divider = 0;

    always @(posedge clk) begin
        divider <= divider + 1;
    end

    assign r = divider[24];
    assign g = divider[25];
    assign b = divider[26];

    assign p5  = clk;
    assign p6  = divider[10];
    assign p9  = divider[11];
    assign p10 = divider[12];
    assign p11 = divider[13];
    assign p12 = divider[14];
    assign p13 = divider[15];
    assign p0  = divider[16];
    assign p1  = divider[17];

endmodule

