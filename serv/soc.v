
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
    parameter memsize = 8192;

    localparam GPIO_ADDR = 8'h40;
    localparam SPI_ADDR  = 8'h50;
    localparam UART_ADDR = 8'h60;

    //  Interface with the CPU's Wishbone bus

    wire wb_clk;
    wire wb_rst;

    assign wb_clk = ck;
    assign wb_rst = rst;
 
    //  SPI

`ifdef SPI
    wire spi_ack;
    wire [31:0] spi_rdt;

    spi #(.ADDR(SPI_ADDR), .AWIDTH(8))
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
`else
    wire [31:0] spi_rdt;
    wire spi_ack;
    assign spi_rdt = 32'h0;
    assign spi_ack = 1'b0;
    assign spi_cs = 1'b1;
    assign spi_sck = 1'b1;
    assign spi_mosi = 1'b1;
`endif // SPI

    //  UART

    wire baud_en;

    uart_baud #(.DIVIDE(8)) uart_clock (.ck(wb_clk), .baud_ck(baud_en));

    wire [31:0] uart_rdt;
    wire uart_ack;
    
    uart
        #(.ADDR(UART_ADDR), .AWIDTH(8))
        uart_io (
        // cpu bus
        .wb_clk(wb_clk),
        .wb_rst(wb_rst),
        .wb_dbus_adr(wb_dbus_adr),
        .wb_dbus_dat(wb_dbus_dat),
        .wb_dbus_sel(wb_dbus_sel),
        .wb_dbus_we(wb_dbus_we),
        .wb_dbus_cyc(wb_dbus_cyc),
        .rdt(uart_rdt),
        .ack(uart_ack),
        // IO
        .baud_en(baud_en),
        .tx(tx)
    );

    //  GPIO

    wire [31:0] gpio_rdt;
    wire gpio_ack;

    /* verilator lint_off UNUSED */
    wire [7:0] gpio_reg;
    /* verilator lint_on UNUSED */
    
    gpio
        #(.ADDR(GPIO_ADDR), .AWIDTH(8))
        gpio_io (
        // cpu bus
        .wb_clk(wb_clk),
        .wb_rst(wb_rst),
        .wb_dbus_adr(wb_dbus_adr),
        .wb_dbus_dat(wb_dbus_dat),
        .wb_dbus_sel(wb_dbus_sel),
        .wb_dbus_we(wb_dbus_we),
        .wb_dbus_cyc(wb_dbus_cyc),
        .rdt(gpio_rdt),
        .ack(gpio_ack),
        // IO
        .gpio(gpio_reg)
    );

    assign led = gpio_reg[0];

    //  Data Bus IO

    assign wb_xbus_ack = gpio_ack | uart_ack | spi_ack;
    assign wb_xbus_rdt = gpio_rdt | uart_rdt | spi_rdt;

    //  Test outputs

    assign test[0] = tx;
    assign test[1] = spi_cs;
    assign test[2] = spi_mosi;
    assign test[3] = spi_miso;
    assign test[4] = spi_ack;
    assign test[5] = spi_sck;
    assign test[6] = wb_dbus_cyc;
    assign test[7] = 0;

endmodule

