
module soc (
    input wire clk,
    output wire [7:0] test,
    output wire led,
    output wire tx
);

    parameter memfile = "firmware.hex";
    parameter memsize = 8192;

    // PLL
    wire i_clk;
    assign i_clk = clk;
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

    wire wb_rst;
    assign wb_rst = rst_reg[0];

    //  Continually Reset the cpu

    reg [11:0] reseter = 0;

    always @(posedge wb_clk) begin
        reseter <= reseter + 1;
    end

    assign reset_req = reseter == 0;

    //  Interface with the CPU's Wishbone bus

    /* verilator lint_off UNUSED */
    wire [31:0] wb_dbus_adr;
    wire [3:0] wb_dbus_sel;
    wire [31:0] wb_dbus_dat;
    /* verilator lint_on UNUSED */
    wire wb_dbus_we;
    wire wb_dbus_cyc;
    wire [31:0] wb_dbus_rdt;
    wire wb_dbus_ack;

    //  Chip Selects

    wire gpio_cyc;
    wire gpio_ack;

    arb #(.ADDR(8'h40), .WIDTH(8))
        arb_gpio (
        .wb_ck(wb_clk), 
        .addr(wb_dbus_adr[31:31-7]), 
        .wb_cyc(wb_dbus_cyc), 
        .wb_rst(wb_rst),
        .ack(gpio_ack), 
        .en(gpio_cyc)
    );

    wire uart_cyc;
    wire uart_ack;

    arb #(.ADDR(8'h60), .WIDTH(8))
        arb_uart (
        .wb_ck(wb_clk), 
        .addr(wb_dbus_adr[31:31-7]), 
        .wb_cyc(wb_dbus_cyc), 
        .wb_rst(wb_rst),
        .ack(uart_ack), 
        .en(uart_cyc)
    );

    //  UART
    
    wire baud_en;

    uart_baud #(.DIVIDE(32)) uart_clock (.ck(wb_clk), .baud_ck(baud_en));

    wire uart_we;
    assign uart_we = uart_cyc & wb_dbus_we;
    /* verilator lint_off UNUSED */
    wire uart_ready;
    /* verilator lint_on UNUSED */
    uart_tx uart(
        .ck(wb_clk),
        .baud_ck(baud_en),
        .in(wb_dbus_dat[7:0]),
        .we(uart_we),
        .ready(uart_ready),
        .tx(tx));

    //  GPIO

    wire gpio_rdt;
    servant_gpio gpio (
        .i_wb_clk (wb_clk),
        .i_wb_dat (wb_dbus_dat[0]),
        .i_wb_we  (wb_dbus_we),
        .i_wb_cyc (gpio_cyc),
        .o_wb_rdt (gpio_rdt),
        .o_gpio   (led)
    );

    //

    assign wb_dbus_ack = gpio_ack | uart_ack;
    assign wb_dbus_rdt = gpio_cyc ? { 31'h0, gpio_rdt } : 0;

    //  Test outputs
 
    assign test[0] = wb_clk;
    assign test[1] = wb_rst;
    assign test[2] = led;
    assign test[3] = tx;
    assign test[4] = gpio_cyc;
    assign test[5] = uart_cyc;
    assign test[6] = 0;
    assign test[7] = wb_dbus_ack;

    // CPU
    servant #(.memfile (memfile), .memsize (memsize))
        servant (.wb_clk (wb_clk), .wb_rst (wb_rst), 
           .wb_dbus_adr(wb_dbus_adr),
           .wb_dbus_dat(wb_dbus_dat),
           .wb_dbus_sel(wb_dbus_sel),
           .wb_dbus_we(wb_dbus_we),
           .wb_dbus_cyc(wb_dbus_cyc),
           .wb_xbus_rdt(wb_dbus_rdt),
           .wb_xbus_ack(wb_dbus_ack));

endmodule

