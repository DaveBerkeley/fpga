
module soc (
    input  wire ck,
    input  wire rst,

    // cpu bus
    /* verilator lint_off UNUSED */
    input [31:0] wb_dbus_adr,
    input [31:0] wb_dbus_dat,
    input [3:0] wb_dbus_sel,
    /* verilator lint_on UNUSED */
    input wb_dbus_we,
    input wb_dbus_cyc,
    output [31:0] wb_xbus_rdt,
    output wb_xbus_ack,
    
    // SPI interface
    output wire spi_cs,
    output wire spi_sck,
    input  wire spi_miso,
    output wire spi_mosi,
    // other io
    output wire [7:0] test,
    output wire led,
    output wire tx
);

    parameter memfile = "firmware.hex";
    parameter memsize = 4096; // 8192;

    //  Interface with the CPU's Wishbone bus

    wire wb_clk;
    wire wb_rst;

    assign wb_clk = ck;
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
        .cyc(gpio_cyc)
    );

    wire spi_ack;
    wire [31:0] spi_rdt;

    spi #(.ADDR(8'h50), .AWIDTH(8))
    spi_io(
        // cpu bus
        .wb_clk(wb_clk),
        .wb_rst(wb_rst),
        .wb_dbus_adr(wb_dbus_adr),
        .wb_dbus_dat(wb_dbus_dat),
        .wb_dbus_sel(wb_dbus_sel),
        .wb_dbus_we(wb_dbus_we),
        .wb_dbus_cyc(wb_dbus_cyc),
        .rdt(spi_rdt),
        .ack(spi_ack),
        // IO
        .cs(spi_cs),
        .sck(spi_sck),
        .mosi(spi_mosi),
        .miso(spi_miso)
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
        .cyc(uart_cyc)
    );

    //  UART
    
    wire baud_en;

    uart_baud #(.DIVIDE(8)) uart_clock (.ck(wb_clk), .baud_ck(baud_en));

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

    //  Data Bus Reads

    /* verilator lint_off UNUSED */
    function [31:0] rdt(input [1:0] addr);
        begin
            if (gpio_cyc)
                rdt = { 24'h0, gpio };
            else if (uart_cyc)
                rdt = { 31'h0, uart_rdt };
            else
                rdt = 0;
        end
    endfunction
    /* verilator lint_on UNUSED */

    assign wb_xbus_ack = gpio_ack | uart_ack | spi_ack;
    assign wb_xbus_rdt = rdt(wb_dbus_adr[3:2]) | spi_rdt;

    //  Test outputs

    assign test[0] = spi_sck;
    assign test[1] = spi_cs;
    assign test[2] = spi_mosi;
    assign test[3] = spi_miso;
    assign test[4] = spi_ack;
    assign test[5] = tx;
    assign test[6] = wb_dbus_cyc;
    assign test[7] = 0;

endmodule

