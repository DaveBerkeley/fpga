
module top (
    input wire ck,
    input wire en,
    input wire clr,
    input wire [15:0] x,
    input wire [15:0] y,
    output wire [39:0] acc_out
);

    wire neg_x;
    assign neg_x = x[15];
    wire neg_y;
    assign neg_y = y[15];

    wire [15:0] ux;
    wire [15:0] uy;

    // pipeline t=1 : conditionally invert / latch the input data

    twos_complement x2c(.ck(ck), .inv(neg_x), .in(x), .out(ux));
    twos_complement y2c(.ck(ck), .inv(neg_y), .in(y), .out(uy));

    // pipeline t=2 : multiply the unsigned x & y values

    wire [31:0] mul_xy;
    multiplier mul(.ck(ck), .a(ux), .b(uy), .out(mul_xy));

    // pipeline t=3 : accumulate the data

    wire acc_rst, acc_en;
    pipe #(.LENGTH(2)) p_clr(.ck(ck), .rst(1'b1), .in(clr), .out(acc_rst));
    pipe #(.LENGTH(2)) p_en (.ck(ck), .rst(1'b1), .in(en),  .out(acc_en));

    reg acc_add;

    always @(posedge ck) begin
        acc_add <= !(neg_x ^ neg_y);
    end

    accumulator acc(.ck(ck), .en(acc_en), .rst(acc_rst), .add(acc_add), .in(mul_xy), .out(acc_out));

    // pipeline t=4 : data ready

endmodule


