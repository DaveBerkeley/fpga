
module top(
    input wire CLK, 
    output wire TX, 
    output wire LED1,
    output wire P1A1,
    output wire P1A2,
    output wire P1A3,
    output wire P1A4,
    output wire P1B1,
    output wire P1B2,
    output wire P1B3,
    output wire P1B4
);

    wire led;
    assign LED1 = led;

    parameter memfile = "firmware.hex";
    //parameter memfile = "/home/dave/Desktop/serv/sw/zephyr_hello.hex";
    parameter memsize = 8192;

    assign TX = led;

    // PLL
    wire i_clk;
    assign i_clk = CLK;
    wire o_clk;
    /* verilator lint_off UNUSED */
    wire locked;
    /* verilator lint_on UNUSED */
    pll clock(.clock_in(i_clk), .clock_out(o_clk), .locked(locked));
 
    wire wb_clk;
    assign wb_clk = o_clk;

    // Reset generator
    reg [4:0] rst_reg = 5'b11111;

    always @(posedge wb_clk) begin
        rst_reg <= {1'b0, rst_reg[4:1]};
    end

    wire o_rst;
    assign o_rst = rst_reg[0];

    wire [7:0] test;

    assign P1A1 = test[0];
    assign P1A2 = test[1];
    assign P1A3 = test[2];
    assign P1A4 = test[3];
    assign P1B1 = test[4];
    assign P1B2 = test[5];
    assign P1B3 = test[6];
    assign P1B4 = test[7];

    // CPU
    servant #(.memfile (memfile), .memsize (memsize))
        servant (.wb_clk (wb_clk), .wb_rst (o_rst), .q(led), .test(test));

endmodule
