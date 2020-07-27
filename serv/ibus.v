
module ibus
    (
    input wire wb_clk,
    input wire wb_rst,
    // ibus interface
    /* verilator lint_off UNUSED */
    input wire [31:0] wb_ibus_adr,
    /* verilator lint_on UNUSED */
    output wire [31:0] wb_ibus_rdt,
    input wire wb_ibus_cyc,
    output wire wb_ibus_ack,
    // SPI interface
    output wire spi_cs,
    output wire spi_sck,
    output wire spi_mosi,
    input  wire spi_miso
);

    // XiP (Execute in place) : fetch ibus requests from Flash

    wire spi_ready;
    wire start;
    wire ack;
    reg fetching = 0;

    assign ack = fetching & spi_ready;

    wire [31:0] spi_rdata;

    always @(posedge wb_clk) begin
        if (start)
            fetching <= 1;
        if (fetching & spi_ready) begin
            fetching <= 0;
        end
    end

    wire [31:0] rdata = { spi_rdata[7:0], spi_rdata[15:8], spi_rdata[23:16], spi_rdata[31:24] };
    assign wb_ibus_rdt = wb_ibus_cyc ? rdata : 0;

    reg [7:0] spi_code;
    reg spi_tx_addr;
    reg spi_no_read;
   
    initial spi_code = 8'h03; // SPI READ
    initial spi_tx_addr = 1;
    initial spi_no_read = 0;

    // SPI Flash Command Codes
    localparam SPI_READ      = 8'h03;
    localparam SPI_RESET_EN  = 8'h66;
    localparam SPI_RESET_REQ = 8'h99;

    localparam RESET = 0;
    localparam RESET_EN_START = 1;
    localparam RESET_EN = 2;
    localparam RESET_REQ_START = 3;
    localparam RESET_REQ = 4;
    localparam WAITING = 5;
    localparam RUNNING = 6;

    reg [2:0] state;
    reg rst_start = 0;
    reg [9:0] wait_ck = 0;

    always @(posedge wb_clk) begin

        if (wb_rst) begin
            state <= RESET;
            wait_ck <= 0;
        end

        if ((state == RESET) & !wb_rst) begin
            // Start sending the RESET_EN command
            state <= RESET_EN_START;
            spi_code <= SPI_RESET_EN;
            spi_tx_addr <= 0;
            spi_no_read <= 1;
            rst_start <= 1;
        end

        if (state == RESET_EN_START) begin
            rst_start <= 0;
            state <= RESET_EN;
        end

        if ((state == RESET_EN) & spi_ready) begin
            // Start sending the RESET_REQ command
            state <= RESET_REQ_START;
            spi_code <= SPI_RESET_REQ;
            spi_tx_addr <= 0;
            spi_no_read <= 1;
            rst_start <= 1;                
        end

        if (state == RESET_REQ_START) begin
            rst_start <= 0;
            state <= RESET_REQ;
        end

        if ((state == RESET_REQ) & spi_ready) begin
            state <= WAITING;
            // Configure for normal running
            spi_code <= SPI_READ;
            spi_tx_addr <= 1;
            spi_no_read <= 0;
        end

        if (state == WAITING) begin
            // Wait >30us for the flash reset to complete
            wait_ck <= wait_ck +1;
            if (wait_ck == 10'h3FF) begin
                state <= RUNNING;
            end
        end

    end

    assign start = (state == RUNNING) ? (wb_ibus_cyc & spi_ready & !fetching) : rst_start;

    spi_tx spi(
        .ck(wb_clk),
        // SPI io
        .cs(spi_cs),
        .sck(spi_sck),
        .mosi(spi_mosi),
        .miso(spi_miso),
        // control
        .code(spi_code),
        .tx_addr(spi_tx_addr),
        .no_read(spi_no_read),
        // WB Bus
        .addr(wb_ibus_adr[23:0] | 24'h100000),
        .req(start),
        // SPI status / data
        .rdata(spi_rdata),
        .ready(spi_ready)
    );

    assign wb_ibus_ack = ack && (state == RUNNING);

endmodule


