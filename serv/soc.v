
module soc (
    input wire clk,
    input wire rst,
    output wire [7:0] test,
    output wire led,
    output wire tx
);

    parameter memfile = "firmware.hex";
    parameter memsize = 8192;

    //  Interface with the CPU's Wishbone bus

    wire wb_clk;
    wire wb_rst;
    /* verilator lint_off UNUSED */
    wire [31:0] wb_dbus_adr;
    wire [3:0] wb_dbus_sel;
    wire [31:0] wb_dbus_dat;
    /* verilator lint_on UNUSED */
    wire wb_dbus_we;
    wire wb_dbus_cyc;
    wire [31:0] wb_dbus_rdt;
    wire wb_dbus_ack;

    assign wb_clk = clk;
    assign wb_rst = rst;
 
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
    wire uart_ready;

    wire [0:0] uart_rdt;

    uart_tx uart(
        .ck(wb_clk),
        .baud_ck(baud_en),
        .in(wb_dbus_dat[7:0]),
        .we(uart_we),
        .ready(uart_ready),
        .tx(tx));

    assign uart_rdt = { uart_ready };

    //  GPIO

    reg [7:0] gpio = 0;

    always @(posedge wb_clk) begin
        if (gpio_cyc) begin
            if (wb_dbus_we)
                gpio <= wb_dbus_dat[7:0];
        end
    end

    assign led = gpio[0];

    //

    function [31:0] rdt();
        begin
            if (gpio_cyc)
                rdt = { 24'h0, gpio };
            else if (uart_cyc)
                rdt = { 31'h0, uart_rdt };
            else
                rdt = 0;
        end
    endfunction

    assign wb_dbus_ack = gpio_ack | uart_ack;
    assign wb_dbus_rdt = rdt();

    //  Test outputs

    reg toggle = 0;

    always @(posedge wb_clk)
        toggle <= !toggle;
 
    assign test[0] = wb_clk;
    assign test[1] = wb_rst;
    assign test[2] = tx;
    assign test[3] = led;
    assign test[4] = gpio_cyc;
    assign test[5] = uart_cyc;
    assign test[6] = gpio[0];
    assign test[7] = toggle;

    // CPU
    servant #(.memfile (memfile), .memsize (memsize))
        servant (
            .wb_clk (wb_clk), 
            .wb_rst (wb_rst), 
            .wb_dbus_adr(wb_dbus_adr),
            .wb_dbus_dat(wb_dbus_dat),
            .wb_dbus_sel(wb_dbus_sel),
            .wb_dbus_we(wb_dbus_we),
            .wb_dbus_cyc(wb_dbus_cyc),
            .wb_xbus_rdt(wb_dbus_rdt),
            .wb_xbus_ack(wb_dbus_ack)
    );

endmodule

