
module top(input wire CLK, output wire TX);

    wire led;
    assign TX = led;

    //parameter memfile = "firmware.hex";
    parameter memfile = "/home/dave/Desktop/serv/sw/zephyr_hello.hex";
    parameter memsize = 8192;

    // PLL
    wire i_clk;
    assign i_clk = CLK;
    wire wb_clk;
    /* verilator lint_off UNUSED */
    wire locked;
    /* verilator lint_on UNUSED */
    pll clock(.clock_in(i_clk), .clock_out(wb_clk), .locked(locked));
 
    // Reset generator
    reg [4:0] rst_reg = 5'b11111;

    always @(posedge wb_clk) begin
        rst_reg <= {1'b0, rst_reg[4:1]};
    end
 
    wire o_rst;
    assign o_rst = rst_reg[0];

    // CPU
    servant #(.memfile (memfile), .memsize (memsize))
        servant (.wb_clk (wb_clk), .wb_rst (o_rst), .q(led));

endmodule