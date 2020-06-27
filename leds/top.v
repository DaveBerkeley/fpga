
module top (input CLK, output P1A1, output P1A2);

wire ck;
wire led_data;
wire led_ck;

assign ck = CLK;
assign P1A1 = led_data;
assign P1A2 = led_ck;

wire we;
wire [3:0] waddr;
wire [31:0] wdata;
wire re;
wire [3:0] raddr;
/* verilator lint_off UNUSED */
wire [31:0] rdata;
/* verilator lint_on UNUSED */

dpram #(.BITS(32), .SIZE(16)) ram_ (.clk(ck),
    .we(we), .waddr(waddr), .wdata(wdata),
    .re(re), .raddr(raddr), .rdata(rdata)
);

led_sk9822 leds (.clk(ck), .led_data(led_data), .led_ck(led_ck), .re(re), .raddr(raddr), .rdata(rdata[23:0]));

ram_write writer(.clk(ck), .we(we), .waddr(waddr), .wdata(wdata));

endmodule

