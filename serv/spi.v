
module spi_tx(
    input wire ck,
    output wire cs,
    output wire sck,
    output wire mosi,
    input wire miso,

    input wire [7:0] code,
    input wire [23:0] addr,
    input wire tx_addr,
    input wire no_read,
    input wire req,
    output reg [31:0] rdata,
    output wire ready
);

    initial begin
        rdata = 0;
    end

    reg [31:0] tx = 32'b0;
    reg [6:0] bit_count = 0;
    wire sending;
    assign sending = bit_count != 0;

    reg clock = 0;

    function [7:0] reverse(input [7:0] d);

        begin
            reverse = { d[0], d[1], d[2], d[3], d[4], d[5], d[6], d[7] };
        end

    endfunction

    /* verilator lint_off UNUSED */
    reg [31:0] rx = 32'b0;
    /* verilator lint_on UNUSED */

    always @(posedge ck) begin

        clock <= !clock;

        if (req) begin
            if (tx_addr)
                tx <= { reverse(addr[7:0]), reverse(addr[15:8]), reverse(addr[23:16]), reverse(code) };
            else
                tx <= { 24'h0, reverse(code) };

            bit_count <= 8 + (tx_addr ? 24 : 0) + (no_read ? 0 : 32);

            clock <= 0;
        end

        if (clock) begin
            if (sending) begin

                if (bit_count == 1) begin
                    rdata <= { rx[30:0], miso };
                end

                bit_count <= bit_count - 1;
                tx <= { 1'b0, tx[31:1] };
                rx <= { rx[30:0], miso };

            end
        end
    end

    assign mosi  = sending ? tx[0] : 1;
    assign sck   = sending ? clock : 0;
    assign cs    = !sending;
    assign ready = !sending;

endmodule

   /*
    *
    */

module spi
    #(parameter ADDR=0, AWIDTH=8)
    (
    // cpu bus
    input wire wb_clk,
    input wire wb_rst,
    /* verilator lint_off UNUSED */
    input [31:0] wb_dbus_adr,
    input [31:0] wb_dbus_dat,
    input [3:0] wb_dbus_sel,
    /* verilator lint_on UNUSED */
    input wb_dbus_we,
    input wb_dbus_cyc,
    output wire [31:0] rdt,
    output wire ack,
    // IO
    output wire cs,
    output wire sck,
    output wire mosi,
    input wire miso
);

    wire cyc;

    chip_select #(.ADDR(ADDR), .WIDTH(AWIDTH))
        cs_spi (
        .wb_ck(wb_clk), 
        .addr(wb_dbus_adr[31:24]), 
        .wb_cyc(wb_dbus_cyc), 
        .wb_rst(wb_rst),
        .ack(ack), 
        .cyc(cyc)
    );

    // Control Register :
    //
    // not_used[22], incr_addr, tx_addr, command[8]

    localparam SPI_CTRL_W = 8 + 1 + 1 + 1;
    reg [(SPI_CTRL_W-1):0] spi_cmd;
    wire [7:0] spi_code;
    wire spi_inc;
    wire spi_tx_addr;
    wire spi_no_read;

    assign spi_code     = spi_cmd[7:0];
    assign spi_tx_addr  = spi_cmd[8];
    assign spi_inc      = spi_cmd[9];
    assign spi_no_read  = spi_cmd[10];

    reg [23:0] spi_addr;
    reg spi_req = 0;
    
    wire [31:0] spi_rdata;
    wire spi_ready;

    // Allow programatic writes to SPI tx regs
    always @(posedge wb_clk) begin
        if (cyc) begin
            if (wb_dbus_we) begin
                if (!wb_dbus_adr[2]) begin
                    spi_cmd <= wb_dbus_dat[(SPI_CTRL_W-1):0];
                    spi_req <= 1;
                end else begin
                    spi_addr <= wb_dbus_dat[23:0];
                end
            end
        end
        if (spi_req) begin
            spi_req <= 0;
            if (spi_inc) begin
                spi_addr <= spi_addr + 4;
            end
        end
    end

    spi_tx spi(
        .ck(wb_clk),
        .cs(cs),
        .sck(sck),
        .mosi(mosi),
        .miso(miso),
        .code(spi_code),
        .addr(spi_addr),
        .tx_addr(spi_tx_addr),
        .no_read(spi_no_read),
        .req(spi_req),
        .rdata(spi_rdata),
        .ready(spi_ready)
    );

    function [31:0] make_rdt(input [1:0] addr);
        begin
            if (cyc)
                make_rdt = (addr == 0) ? spi_rdata : { 31'b0, spi_ready };
            else
                make_rdt = 0;
        end
    endfunction

    assign rdt = make_rdt(wb_dbus_adr[3:2]);

endmodule
