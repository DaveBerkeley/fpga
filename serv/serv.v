
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
    wire reset_req;

    always @(posedge wb_clk) begin
        if (reset_req)
            rst_reg <= 5'b11111;
        else
            rst_reg <= {1'b0, rst_reg[4:1]};
    end

    wire o_rst;
    assign o_rst = rst_reg[0];


    //  Continually Reset the cpu

    reg [11:0] reseter = 0;

    always @(posedge wb_clk) begin
        reseter <= reseter + 1;
    end

    assign reset_req = reseter == 0;

    /* verilator lint_off UNUSED */
    wire [7:0] test;
    /* verilator lint_on UNUSED */

    assign P1A1 = test[0];
    assign P1A2 = test[1];
    assign P1A3 = test[2];
    assign P1A4 = test[3];
    assign P1B1 = test[4];
    assign P1B2 = test[5];
    assign P1B3 = test[6];
    assign P1B4 = test[7];

    /* verilator lint_off UNUSED */
   wire [31:0] 	wb_dbus_adr;
   wire [31:0] 	wb_dbus_dat;
   wire [3:0] 	wb_dbus_sel;
   wire 	wb_dbus_we;
   wire 	wb_dbus_cyc;
   reg [31:0] 	wb_dbus_rdt = 0;
   reg 	wb_dbus_ack = 0;
   /* verilator lint_on UNUSED */
    
    // CPU
    servant #(.memfile (memfile), .memsize (memsize))
        servant (.wb_clk (wb_clk), .wb_rst (o_rst), 
           .wb_dbus_adr(wb_dbus_adr),
           .wb_dbus_dat(wb_dbus_dat),
           .wb_dbus_sel(wb_dbus_sel),
           .wb_dbus_we(wb_dbus_we),
           .wb_dbus_cyc(wb_dbus_cyc),
           .wb_xbus_rdt(wb_dbus_rdt),
           .wb_xbus_ack(wb_dbus_ack),
           .q(led), .test(test));

endmodule
