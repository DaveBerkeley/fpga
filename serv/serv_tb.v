
`default_nettype none
`timescale 1ns / 100ps

task tb_assert(input test);

    begin
        if (!test)
        begin
            $display("ASSERTION FAILED in %m");
            $finish;
        end
    end

endtask


module SB_PLL40_PAD
    #(
        parameter FEEDBACK_PATH = 0,
        parameter [3:0] DIVR = 0,
        parameter [2:0] DIVQ = 0,
        parameter [2:0] FILTER_RANGE = 0,
        parameter [6:0] DIVF = 0
    )
    (   
        /* verilator lint_off UNUSED */
        input RESETB,
        input PACKAGEPIN,
        input BYPASS,
        output PLLOUTCORE = 0,
        output LOCK = 1
        /* verilator lint_on UNUSED */
    );

    always @(posedge PACKAGEPIN) begin
        PLLOUTCORE <= !PLLOUTCORE;
    end

endmodule

   /*
    *
    */

module top (output wire TX);

    wire led;
    assign TX = led;

    initial begin
        $dumpfile("serv.vcd");
        $dumpvars(0, top);
        #500000 $finish;
    end

    reg CLK = 0;

    always #7 CLK <= !CLK;

    parameter memfile = "firmware.hex";
    parameter memsize = 8192;

    // PLL
    wire i_clk;
    assign i_clk = CLK;
    wire wb_clk;
    /* verilator lint_off UNUSED */
    wire locked;
    /* verilator lint_on UNUSED */
    pll clock(.clock_in(i_clk), .clock_out(wb_clk), .locked(locked));
 
    // Reset generator
    reg [4:0] rst_reg = 5'b11111;

    always @(posedge wb_clk) begin
        rst_reg <= {1'b0, rst_reg[4:1]};
    end

    wire wb_rst;
    assign wb_rst = rst_reg[0];
 
   /*
    *   UART Test
    */

    wire ck;
    assign ck = wb_clk;

    reg [7:0] data_in;
    reg uart_we = 0;
    wire ready;
    wire tx;

    reg [8:0] baud = 0;

    always @(posedge ck) begin
        if (baud == 277)
            baud <= 0;
        else
            baud <= baud + 1;
    end

    wire baud_ck;
    assign baud_ck = baud == 0;

    uart_tx uart(.ck(ck), .baud_ck(baud_ck), .in(data_in), .we(uart_we), .ready(ready), .tx(tx));

    integer i;

    initial begin
        for (i = 0; i < 10; i = i + 1) begin
            @(posedge ck);
        end
        data_in <= 8'haa;
        uart_we <= 1;
        @(posedge ck);
        uart_we <= 0;

        tb_assert(tx == 1); // line level
        @(posedge baud_ck);
        tb_assert(tx == 1); // line level
        @(posedge baud_ck);
        tb_assert(tx == 0); // start bit
        @(posedge baud_ck);
        tb_assert(tx == 0); // bit[0]
        @(posedge baud_ck);
        tb_assert(tx == 1); // bit[1]
        @(posedge baud_ck);
        tb_assert(tx == 0); // bit[2]
        @(posedge baud_ck);
        tb_assert(tx == 1); // bit[3]
        @(posedge baud_ck);
        tb_assert(tx == 0); // bit[4]
        @(posedge baud_ck);
        tb_assert(tx == 1); // bit[5]
        @(posedge baud_ck);
        tb_assert(tx == 0); // bit[6]
        tb_assert(ready == 0);
        @(posedge baud_ck);
        tb_assert(tx == 1); // bit[7]
        tb_assert(ready == 0);
        @(posedge ck);
        @(posedge ck);
        tb_assert(ready == 1);

        // ready is set, so we can load the next byte
        @(posedge ck);
        data_in <= 8'h55;
        uart_we <= 1;
        @(posedge ck);
        uart_we <= 0;

        @(posedge baud_ck);
        tb_assert(tx == 1); // stop bit
        tb_assert(ready == 0);
        @(posedge baud_ck);
        tb_assert(tx == 0); // start bit
        @(posedge baud_ck);
        tb_assert(tx == 1); // bit[0]
        @(posedge baud_ck);
        tb_assert(tx == 0); // bit[1]
        @(posedge baud_ck);
        tb_assert(tx == 1); // bit[2]
        @(posedge baud_ck);
        tb_assert(tx == 0); // bit[3]
        @(posedge baud_ck);
        tb_assert(tx == 1); // bit[4]
        @(posedge baud_ck);
        tb_assert(tx == 0); // bit[5]
        @(posedge baud_ck);
        tb_assert(tx == 1); // bit[6]
        @(posedge baud_ck);
        tb_assert(tx == 0); // bit[7]
        @(posedge baud_ck);
        tb_assert(tx == 1); // stop bit
    end

   /*
    *
    */

    // CPU

    wire [7:0] test;

    wire spi_cs;
    wire spi_sck;
    wire spi_mosi;
    reg  spi_miso = 0;

    reg [1:0] miso = 0;

    always @(posedge wb_clk) begin
        miso <= miso + 1;
        if (!miso[0])
            spi_miso = !spi_miso;
    end

    reg  [31:0] wb_dbus_adr = 0;
    reg  [31:0] wb_dbus_dat = 0;
    reg  [3:0] wb_dbus_sel = 0;
    reg  wb_dbus_we = 0;
    reg  wb_dbus_cyc = 0;
    wire [31:0] wb_dbus_rdt;
    wire wb_dbus_ack;

    soc soc (
        .ck (wb_clk), 
        .rst (wb_rst), 
        // cpu
        .wb_dbus_adr(wb_dbus_adr),
        .wb_dbus_dat(wb_dbus_dat),
        .wb_dbus_sel(wb_dbus_sel),
        .wb_dbus_we(wb_dbus_we),
        .wb_dbus_cyc(wb_dbus_cyc),
        .wb_xbus_rdt(wb_dbus_rdt),
        .wb_xbus_ack(wb_dbus_ack),
        // SPI
        .spi_cs(spi_cs),
        .spi_sck(spi_sck),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .test(test),
        .led(led),
        .tx(tx)
    );

    task write (input [31:0] addr, input [31:0] data);

        wb_dbus_adr <= addr;
        wb_dbus_dat <= data;
        wb_dbus_cyc <= 1;
        wb_dbus_we <= 1;
        wb_dbus_sel <= 4'b1111;
        @(posedge ck);
        @(posedge ck);
        wb_dbus_cyc <= 0;
        wb_dbus_we <= 0;
        wb_dbus_sel <= 4'b0;
        @(posedge ck);
        wb_dbus_adr <= 0;
        wb_dbus_dat <= 0;

    endtask

    task read (input [31:0] addr);

        wb_dbus_adr <= addr;
        wb_dbus_cyc <= 1;
        wb_dbus_we <= 0;
        wb_dbus_sel <= 4'b0000;
        @(posedge ck);
        @(posedge ck);
        wb_dbus_cyc <= 0;
        @(posedge ck);
        wb_dbus_adr <= 0;

    endtask

    reg [31:0] poll_addr = 0;

    always @(posedge ck) begin
        if (poll_addr) begin
            read(poll_addr);
        end
    end

    localparam SPI_ADDR = 32'h50000004;
    localparam SPI_CTRL = 32'h50000000;

    initial begin
        // wait for reset
        for (i = 0; i < 10; i = i + 1) begin
            @(posedge ck);
        end

        write(SPI_ADDR, 32'h00123456);
        write(SPI_CTRL, 32'h00000303);

        // Wait for 'ready' signal
        poll_addr <= SPI_ADDR;
        wait (wb_dbus_rdt[0]);
        poll_addr <= 0;

        // write to 
    end

endmodule
