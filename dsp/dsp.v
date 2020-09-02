
`default_nettype none

   /*
    *
    */

module dsp (
    input wire ext_ck, 
    output wire tx, 

    // XIP Flash
    output wire spi_sck,
    output wire spi_cs,
    output wire spi_mosi,
    input  wire spi_miso,

    output wire [7:0] test,

    // sk9822 drive
    output wire led_ck,
    output wire led_data,

    // I2S
    output wire sck,
    output wire ws,
    // Mic in
    input wire sd_in0,
    input wire sd_in1,
    input wire sd_in2,
    input wire sd_in3,
    
    // I2S Output
    output wire o_sck,
    output wire o_ws,
    output wire o_sd,

    // External I2S sync input, SD output
    input wire ext_sck,
    input wire ext_ws,
    output wire ext_sd
);

    parameter PLL_HZ = 30000000;
    //parameter PLL_HZ = 24000000;

    // Device addresses (addr[31:24])
    localparam GPIO_ADDR  = 8'h40;
    localparam UART_ADDR  = 8'h50;
    localparam FLASH_ADDR = 8'h70;
    localparam IRQ_ADDR   = 8'h80;
    localparam LED_ADDR   = 8'h90;
    localparam TIMER_ADDR = 8'hc0;
    // Run code from this location in memory (Flash)
    localparam RESET_PC   = 32'h0010_0000;

    localparam RUN_SLOW = 0;        // Divide the CPU clock down for development
    localparam RESET_LOOP = 0;      // Repeatedly reset the CPU
    localparam TIMER_ENABLED = 1;   // Hardware Timer

    localparam CK_HZ = RUN_SLOW ? (PLL_HZ/16) : PLL_HZ;

    // PLL
    wire pll_ck;
    /* verilator lint_off UNUSED */
    wire locked;
    /* verilator lint_on UNUSED */
    pll clock(.clock_in(ext_ck), .clock_out(pll_ck), .locked(locked));

    // Conditonally slow the cpu clock down for development.
    generate
        wire ck;
        if (RUN_SLOW) begin
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
    wire reset_req;
    wire rst;

    reset #(.LENGTH(80)) reset(.ck(ck), .rst_req(reset_req), .rst(rst));

    // Continually Reset the cpu (for development)

    generate 
        if (RESET_LOOP) begin
            reg [(RUN_SLOW ? 21 : 24):0] reseter = 0;

            always @(posedge ck) begin
                reseter <= reseter + 1;
            end

            assign reset_req = reseter == 0;
        end else begin
            assign reset_req = 0;
        end
    endgenerate

    // CPU dbus

    wire [31:0] wb_dbus_adr;
    wire [31:0] wb_dbus_dat;
    wire [31:0] wb_dbus_rdt;
    wire [3:0] wb_dbus_sel;
    wire wb_dbus_we;
    wire wb_dbus_cyc;
    wire wb_dbus_ack;

    // CPU ibus

    wire wb_clk;
    wire wb_rst;
    wire [31:0] wb_ibus_adr;
    wire [31:0] wb_ibus_rdt;
    wire wb_ibus_cyc;
    wire wb_ibus_ack;

    assign wb_clk = ck;
    assign wb_rst = rst;

    //  RAM

    wire ram_ack;
    wire [31:0] ram_rdt;

    //  DMA from DSP, connected to port B of ram_arb

    /* verilator lint_off UNUSED */
    wire dma_cyc;
    wire dma_we;
    wire [3:0] dma_sel;
    wire [31:0] dma_adr;
    wire [31:0] dma_dat;
    wire dma_ack;
    wire [31:0] dma_rdt;
    /* verilator lint_on UNUSED */

    // Output Port X of ram_arb
    wire x_cyc;
    wire x_we;
    wire [3:0] x_sel;
    wire [31:0] x_adr;
    wire [31:0] x_dat;
    wire [31:0] x_rdt;
    wire x_ack;

`ifdef USE_DMA

    ram_arb # (.WIDTH(32))
    ram_arb
    (
        .wb_clk(wb_clk),
        .a_cyc(wb_dbus_cyc),
        .a_we(wb_dbus_we),
        .a_sel(wb_dbus_sel),
        .a_adr(wb_dbus_adr),
        .a_dat(wb_dbus_dat),
        .a_ack(ram_ack),
        .a_rdt(ram_rdt),
        .b_cyc(dma_cyc),
        .b_we(dma_we),
        .b_sel(dma_sel),
        .b_adr(dma_adr),
        .b_dat(dma_dat),
        .b_ack(dma_ack),
        .b_rdt(dma_rdt),
        .x_cyc(x_cyc),
        .x_we(x_we),
        .x_sel(x_sel),
        .x_adr(x_adr),
        .x_dat(x_dat),
        .x_ack(x_ack),
        .x_rdt(x_rdt)
    );

`else   //  USE_DMA

    assign ram_ack = x_ack;
    assign ram_rdt = x_rdt;
    assign dma_ack = 0;
    assign dma_rdt = 0;
    assign x_cyc = wb_dbus_cyc;
    assign x_we = wb_dbus_we;
    assign x_sel = wb_dbus_sel;
    assign x_adr = wb_dbus_adr;
    assign x_dat = wb_dbus_dat;
    // ...

`endif //   USE_DMA

    //  Dbus RAM
    
    wire ram_cs;

    chip_select #(.ADDR(0), .WIDTH(8))
    cs_ram (
        .wb_ck(wb_clk),
        .addr(x_adr[31:24]),
        .wb_cyc(x_cyc),
        .wb_rst(wb_rst),
        .ack(x_ack),
        .cyc(ram_cs)
    );
  
    sp_ram ram (
        .ck(wb_clk),
        .addr(x_adr),
        .cyc(ram_cs),
        .we(x_we),
        .sel(x_sel),
        .wdata(x_dat),
        .rdata(x_rdt)
    );

    //  Risc-V 64-bit Timer

    wire timer_ack;
    wire timer_irq;
    wire [31:0] timer_rdt;

    generate

        if (TIMER_ENABLED) begin

            wire timer_cyc;

            chip_select #(.ADDR(TIMER_ADDR), .WIDTH(8))
            cs_timer (
                .wb_ck(wb_clk),
                .addr(wb_dbus_adr[31:24]),
                .wb_cyc(wb_dbus_cyc),
                .wb_rst(wb_rst),
                .ack(timer_ack),
                .cyc(timer_cyc)
            );

            timer timer (
                .wb_clk(wb_clk),
                .wb_rst(wb_rst),
                .ck_en(1'b1), // no prescale
                .wb_dbus_dat(wb_dbus_dat),
                .wb_dbus_adr(wb_dbus_adr),
                .wb_dbus_we(wb_dbus_we),
                .cyc(timer_cyc),
                .irq(timer_irq),
                .rdt(timer_rdt)
            );

        end else begin

            //  No timer hardware
            assign timer_ack = 0;
            assign timer_irq = 0;
            assign timer_rdt = 0;

        end
    endgenerate

    //  UART

    wire baud_en;

    localparam BAUD = CK_HZ / 115200;
    uart_baud #(.DIVIDE(BAUD)) uart_clock (.ck(wb_clk), .baud_ck(baud_en));

    wire [31:0] uart_rdt;
    wire uart_ack;
    /* verilator lint_off UNUSED */
    wire tx_busy;
    /* verilator lint_on UNUSED */
 
    uart #(.ADDR(UART_ADDR), .AWIDTH(8))
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
        .tx(tx),
        .busy(tx_busy)
    );

    //  GPIO

    wire [31:0] gpio_rdt;
    wire gpio_ack;

    /* verilator lint_off UNUSED */
    wire [7:0] gpio_reg;
    /* verilator lint_on UNUSED */
 
    gpio #(.ADDR(GPIO_ADDR), .AWIDTH(8))
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

`ifdef USE_SK9822

    //  sk9822 LED driver

    wire led_ack;

    sk9822_peripheral #(.ADDR(LED_ADDR))
    sk9822_peripheral(
        .wb_clk(wb_clk),
        .wb_rst(wb_rst),
        .wb_dbus_cyc(wb_dbus_cyc),
        .wb_dbus_we(wb_dbus_we),
        .wb_dbus_adr(wb_dbus_adr),
        .wb_dbus_dat(wb_dbus_dat),
        .ack(led_ack),
        .led_ck(led_ck),
        .led_data(led_data)
    );

`else

    wire led_ack;
    assign led_ack = 0;

`endif  //  USE_SK9822

    //  SPI Flash interface

    // flash_read connection to ibus arb
    wire [31:0] f_adr;
    wire [31:0] f_rdt;
    wire f_cyc;
    wire f_ack;
    // flash_read dbus arb
    wire flash_ack;
    wire [31:0] flash_rdt;
    /* verilator lint_off UNUSED */
    wire flash_busy;
    /* verilator lint_on UNUSED */

    ibus_read #(.ADDR(FLASH_ADDR))
    flash_read (
        .wb_clk(wb_clk),
        .wb_rst(wb_rst),
        .wb_dbus_cyc(wb_dbus_cyc),
        .wb_dbus_we(wb_dbus_we),
        .wb_dbus_adr(wb_dbus_adr),
        .wb_dbus_dat(wb_dbus_dat),
        .wb_dbus_ack(flash_ack),
        .wb_dbus_rdt(flash_rdt),
        .wb_ibus_cyc(f_cyc),
        .wb_ibus_adr(f_adr),
        .wb_ibus_ack(f_ack),
        .wb_ibus_rdt(f_rdt),
        .dev_busy(flash_busy)
    );

    // SPI flash ibus interface
    // Run XiP over this

    wire [31:0] s_adr;
    wire [31:0] s_rdt;
    wire s_cyc;
    wire s_ack;
    /* verilator lint_off UNUSED */
    wire ibus_ready;
    /* verilator lint_on UNUSED */

    ibus ibus (
        .wb_clk(ck),
        .wb_rst(rst),
        // iBus interface
        .wb_ibus_adr(s_adr),
        .wb_ibus_rdt(s_rdt),
        .wb_ibus_cyc(s_cyc),
        .wb_ibus_ack(s_ack),
        // SPI interface
        .spi_cs(spi_cs),
        .spi_sck(spi_sck),
        .spi_miso(spi_miso),
        .spi_mosi(spi_mosi),
        .ready(ibus_ready)
    );

    //  iBus arbitration between CPU and flash_read

    /* verilator lint_off UNUSED */
    wire arb_busy;
    /* verilator lint_on UNUSED */

    bus_arb ibus_arb(
        .wb_clk(ck),
        // CPU is the priority channel
        .a_cyc(wb_ibus_cyc),
        .a_adr(wb_ibus_adr),
        .a_ack(wb_ibus_ack),
        .a_rdt(wb_ibus_rdt),
        // Flash_read at a lower priority
        .b_cyc(f_cyc),
        .b_adr(f_adr),
        .b_ack(f_ack),
        .b_rdt(f_rdt),
        // Connect to the ibus SPI controller
        .x_cyc(s_cyc),
        .x_adr(s_adr),
        .x_ack(s_ack),
        .x_rdt(s_rdt),
        .busy(arb_busy)
    );

    wire engine_ack;
    wire [31:0] engine_rdt;

    /* verilator lint_off UNUSED */
    wire audio_ready;
    /* verilator lint_on UNUSED */
    wire dma_done;
    wire dma_match;

    assign o_sck = sck;
    assign o_ws = ws;
    assign ext_sd = o_sd;

    audio_engine #(.CK_HZ(CK_HZ)) audio_engine(
        .ck(ck),
        .wb_rst(wb_rst),
        .wb_dbus_cyc(wb_dbus_cyc),
        .wb_dbus_sel(wb_dbus_sel),
        .wb_dbus_we(wb_dbus_we),
        .wb_dbus_adr(wb_dbus_adr),
        .wb_dbus_dat(wb_dbus_dat),
        .ack(engine_ack),
        .rdt(engine_rdt),

        .dma_cyc(dma_cyc),
        .dma_we(dma_we),
        .dma_sel(dma_sel),
        .dma_adr(dma_adr),
        .dma_dat(dma_dat),
        .dma_ack(dma_ack),
        .dma_rdt(dma_rdt),
        .dma_done(dma_done),
        .dma_match(dma_match),

        .sck(sck),
        .ws(ws),
        .sd_out(o_sd),
        .sd_in0(sd_in0),
        .sd_in1(sd_in1),
        .sd_in2(sd_in2),
        .sd_in3(sd_in3),

        .ext_sck(ext_sck),
        .ext_ws(ext_ws),

        .ready(audio_ready),
        .test(test)
    );

    //  Interrupt controller

    wire irq_ack;
    wire [31:0] irq_rdt;

    wire [2:0] irqs;
    assign irqs = { dma_match, dma_done, timer_irq };

    wire soc_irq;

    irq_reg #(.ADDR(IRQ_ADDR), .ADDR_W(8), .REG_WIDTH(3))
    irq_reg 
    (
        .wb_clk(wb_clk),
        .wb_rst(wb_rst),
        .wb_dbus_adr(wb_dbus_adr),
        .wb_dbus_dat(wb_dbus_dat),
        .wb_dbus_we(wb_dbus_we),
        .wb_dbus_cyc(wb_dbus_cyc),
        .ack(irq_ack),
        .rdt(irq_rdt),
        .irq_in(irqs),
        .irq(soc_irq)
    );
    
    // OR the dbus peripherals *_rdt & *_ack together
    // They must be 0 when not active.

    assign wb_dbus_rdt = irq_rdt | timer_rdt | ram_rdt | uart_rdt | gpio_rdt | flash_rdt | engine_rdt;
    assign wb_dbus_ack = irq_ack | timer_ack | ram_ack | uart_ack | gpio_ack | flash_ack | engine_ack | led_ack;

    // SERV CPU

    parameter with_csr = 1;

    serv_rf_top #(.RESET_PC(RESET_PC), .WITH_CSR(with_csr))
    cpu (
        .clk(wb_clk),
        .i_rst(wb_rst),
        .i_timer_irq(soc_irq),
        // iBus
        .o_ibus_adr(wb_ibus_adr),
        .o_ibus_cyc(wb_ibus_cyc),
        .i_ibus_rdt(wb_ibus_rdt),
        .i_ibus_ack(wb_ibus_ack),
        // dBus
        .o_dbus_adr(wb_dbus_adr),
        .o_dbus_dat(wb_dbus_dat),
        .o_dbus_sel(wb_dbus_sel),
        .o_dbus_we(wb_dbus_we),
        .o_dbus_cyc(wb_dbus_cyc),
        .i_dbus_rdt(wb_dbus_rdt),
        .i_dbus_ack(wb_dbus_ack)
    );

endmodule
