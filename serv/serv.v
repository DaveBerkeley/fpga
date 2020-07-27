
module top(
    input wire CLK, 
    output wire TX, 
    output wire FLASH_SCK,
    output wire FLASH_SSB,
    output wire FLASH_IO0,
    /* verilator lint_off UNUSED */
    input  wire FLASH_IO1,
    /* verilator lint_on UNUSED */
    output wire FLASH_IO2,
    output wire FLASH_IO3,
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

    parameter memfile = ""; // firmware.hex";
    parameter memsize = 8192;

    /* verilator lint_off UNUSED */
    wire [7:0] test;
    /* verilator lint_on UNUSED */

    // PLL
    wire pll_ck;
    /* verilator lint_off UNUSED */
    wire locked;
    /* verilator lint_on UNUSED */
    pll clock(.clock_in(CLK), .clock_out(pll_ck), .locked(locked));

    localparam prescale = 1;

    generate
        wire ck;
        if (prescale) begin
            reg [3:0] scale = 0;

            always @(posedge pll_ck) begin
                scale <= scale + 1;
            end

        assign ck = scale[3];
        end else begin
            assign ck = pll_ck;
        end
    endgenerate

    // Reset generator
    reg [4:0] rst_reg = 5'b11111;
    wire reset_req;

    always @(posedge ck) begin
        if (reset_req)
            rst_reg <= 5'b11111;
        else
            rst_reg <= {1'b0, rst_reg[4:1]};
    end

    wire rst;
    assign rst = rst_reg[0];

    //  Continually Reset the cpu

    localparam reset_loop = 1;

    generate 
        if (reset_loop) begin
            reg [13:0] reseter = 0;

            always @(posedge ck) begin
                reseter <= reseter + 1;
            end

            assign reset_req = reseter == 0;
        end else begin
            assign reset_req = 0;
        end
    endgenerate

    wire spi_cs;
    wire spi_sck;
    wire spi_miso;
    wire spi_mosi;

    // connect to the flash chip
    assign FLASH_SCK = spi_sck;
    assign FLASH_SSB = spi_cs;
    assign FLASH_IO0 = spi_mosi;
    assign spi_miso = FLASH_IO1;
    assign FLASH_IO2 = 1;
    assign FLASH_IO3 = 1;

    // connect the soc to the cpu
    wire [31:0] wb_dbus_adr;
    wire [31:0] wb_dbus_dat;
    wire [3:0] wb_dbus_sel;
    wire wb_dbus_we;
    wire wb_dbus_cyc;
    wire [31:0] wb_dbus_rdt;
    wire wb_dbus_ack;

    /* verilator lint_off UNUSED */
    wire dummy_sck;
    wire dummy_cs;
    wire dummy_mosi;
    /* verilator lint_on UNUSED */

    soc soc(
        .ck(ck),
        .rst(rst),
        .test(test),
        // cpu
        .wb_dbus_adr(wb_dbus_adr),
        .wb_dbus_dat(wb_dbus_dat),
        .wb_dbus_sel(wb_dbus_sel),
        .wb_dbus_we(wb_dbus_we),
        .wb_dbus_cyc(wb_dbus_cyc),
        .wb_xbus_rdt(wb_dbus_rdt),
        .wb_xbus_ack(wb_dbus_ack),
        // SPI
        .spi_cs(dummy_cs),
        .spi_sck(dummy_sck),
        .spi_miso(1'b0),
        .spi_mosi(dummy_mosi),
        // IO
        .led(LED1),
        .tx(TX)
    );

    wire [31:0] wb_ibus_adr;
    wire [31:0] wb_ibus_rdt;
    wire wb_ibus_cyc;
    wire wb_ibus_ack;
    
    ibus ibus (
        .wb_clk(ck),
        .wb_rst(rst),
        .wb_ibus_adr(wb_ibus_adr),
        .wb_ibus_rdt(wb_ibus_rdt),
        .wb_ibus_cyc(wb_ibus_cyc),
        .wb_ibus_ack(wb_ibus_ack),
        .spi_cs(spi_cs),
        .spi_sck(spi_sck),
        .spi_miso(spi_miso),
        .spi_mosi(spi_mosi)
    );

    // CPU
    servant #(.memfile (memfile), .memsize (memsize))
        servant (
            .wb_clk (ck), 
            .wb_rst (rst), 
            .wb_ibus_adr(wb_ibus_adr),
            .wb_ibus_cyc(wb_ibus_cyc),
            .wb_ibus_ack(wb_ibus_ack),
            .wb_ibus_rdt(wb_ibus_rdt),
            .wb_dbus_adr(wb_dbus_adr),
            .wb_dbus_dat(wb_dbus_dat),
            .wb_dbus_sel(wb_dbus_sel),
            .wb_dbus_we(wb_dbus_we),
            .wb_dbus_cyc(wb_dbus_cyc),
            .wb_xbus_rdt(wb_dbus_rdt),
            .wb_xbus_ack(wb_dbus_ack)
    );    

    assign P1A1 = test[0];
    assign P1A2 = spi_cs;
    assign P1A3 = spi_sck;
    assign P1A4 = spi_mosi;
    assign P1B1 = spi_miso;
    assign P1B2 = wb_ibus_cyc;
    assign P1B3 = wb_ibus_ack;
    assign P1B4 = test[7];

endmodule
