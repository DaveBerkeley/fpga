
module mac (
    input wire ck,
    input wire en,
    input wire clr,
    input wire req,
    input wire [15:0] x,
    input wire [15:0] y,
    output wire [39:0] out,
    output reg done
);

    wire neg_x;
    assign neg_x = x[15];
    wire neg_y;
    assign neg_y = y[15];

    wire [15:0] ux;
    wire [15:0] uy;

    // pipeline t=1 : conditionally invert / latch the input data

    twos_complement #(.WIDTH(16)) x2c(.ck(ck), .inv(neg_x), .in(x), .out(ux));
    twos_complement #(.WIDTH(16)) y2c(.ck(ck), .inv(neg_y), .in(y), .out(uy));

    // pipeline t=2 : multiply the unsigned x & y values

    wire [31:0] mul_xy;
    multiplier mul(.ck(ck), .a(ux), .b(uy), .out(mul_xy));

    // pipeline t=3 : accumulate the data

    wire acc_en, acc_rst;

    pipe #(.LENGTH(2)) p_en (.ck(ck), .rst(1'b1), .in(en),  .out(acc_en));
    pipe #(.LENGTH(2)) p_clr(.ck(ck), .rst(1'b1), .in(clr), .out(acc_rst));

    reg acc_add;

    // add / sub depending on the signs of the x/y inputs
    reg add_0 = 0;
    always @(posedge ck) begin
        add_0 <= !(neg_x ^ neg_y);
        acc_add <= add_0;
    end

    accumulator #(.OUT_W(40)) 
        acc(.ck(ck), .en(acc_en), .rst(acc_rst), .add(acc_add), .in(mul_xy), .out(out));

    // pipeline t=4 : data ready

    wire req_t1;
    pipe #(.LENGTH(1)) p_req(.ck(ck), .rst(1'b1), .in(req), .out(req_t1));

    initial done = 0;

    always @(posedge ck) begin
        if (clr || req || req_t1)
            done <= 0;
        else
            done <= 1;
    end

endmodule


