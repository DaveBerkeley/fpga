
`default_nettype none
`timescale 1ns / 100ps

task tb_assert(input test);

    begin
        if (!test) begin
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
    wire xspi_cs;
    wire xspi_sck;
    wire xspi_mosi;
    reg  xspi_miso = 0;

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
        .spi_cs(xspi_cs),
        .spi_sck(xspi_sck),
        .spi_mosi(xspi_mosi),
        .spi_miso(xspi_miso),
        .test(test),
        .led(led),
        .tx(tx)
    );

    reg [31:0] wb_ibus_adr = 0;
    reg wb_ibus_cyc = 0;
    wire [31:0] wb_ibus_rdt;
    wire wb_ibus_ack;
    
    ibus ibus (
        .wb_clk(wb_clk),
        .wb_rst(wb_rst),
        .wb_ibus_adr(wb_ibus_adr),
        .wb_ibus_rdt(wb_ibus_rdt),
        .wb_ibus_cyc(wb_ibus_cyc),
        .wb_ibus_ack(wb_ibus_ack),
        .spi_cs(spi_cs),
        .spi_sck(spi_sck),
        .spi_miso(spi_miso),
        .spi_mosi(spi_mosi)
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

    task spi_wait_ready;
        begin
            poll_addr <= SPI_ADDR;
            wait (wb_dbus_rdt[0]);
            poll_addr <= 0;
        end
    endtask

    reg [31:0] i_rdt = 0;

    task iread (input [31:0] addr);

        wb_ibus_adr <= addr;
        wb_ibus_cyc <= 1;
        wait (wb_ibus_ack);
        @(posedge ck);
        // Latch the result
        i_rdt <= wb_ibus_rdt;
        wb_ibus_cyc <= 0;
        wb_ibus_adr <= 32'hZ;

    endtask

    localparam SPI_CTRL = 32'h50000000;
    localparam SPI_ADDR = 32'h50000004;

`ifdef XXXX
    initial begin

        wait (wb_rst == 0);
        @(posedge ck);

        spi_wait_ready();
        write(SPI_ADDR, 32'h00123456);
        write(SPI_CTRL, 32'h00000303);

        spi_wait_ready();
        tb_assert(wb_dbus_rdt == 32'h1);

        write(SPI_CTRL, 32'h00000003);

        spi_wait_ready();
        tb_assert(wb_dbus_rdt == 32'h1);

        read(SPI_CTRL);
        tb_assert(wb_dbus_rdt == 32'haaaaaaaa);

        write(SPI_CTRL, 32'h00000403); // no read

        spi_wait_ready();
        tb_assert(wb_dbus_rdt == 32'h1);

    end
`endif

    initial begin

        wait (wb_rst == 0);
        @(posedge ck);

        iread(32'h00100000);

    end

    // Test bus_arb

    // Device A
    reg         a_cyc = 0;
    reg  [31:0] a_adr = 32'hZ;
    wire        a_ack;
    wire [31:0] a_rdt;
    // Device B
    reg         b_cyc = 0;
    reg  [31:0] b_adr = 32'hZ;
    wire        b_ack;
    wire [31:0] b_rdt;
    // Controlled Device
    wire        x_cyc;
    wire [31:0] x_adr;
    reg         x_ack = 0;
    reg  [31:0] x_rdt = 0;

    bus_arb arb(
        .wb_clk(ck),
        .wb_rst(wb_rst),
        .a_cyc(a_cyc),
        .a_adr(a_adr),
        .a_ack(a_ack),
        .a_rdt(a_rdt),
        .b_cyc(b_cyc),
        .b_adr(b_adr),
        .b_ack(b_ack),
        .b_rdt(b_rdt),
        .x_cyc(x_cyc),
        .x_adr(x_adr),
        .x_ack(x_ack),
        .x_rdt(x_rdt)
    );

    // simulate slow device
    always @(posedge ck) begin
        if (x_cyc) begin
            x_ack <= 1;
            x_rdt <= x_adr;
        end
        if (x_ack) begin
            x_ack <= 0;
            x_rdt <= 0;
        end
    end

    initial begin
        wait (wb_rst == 0);
        @(posedge ck);

        // dev A request
        a_adr <= 32'h12341234;
        a_cyc <= 1;
        wait (a_ack);
        tb_assert(a_rdt == a_adr);
        @(posedge ck);
        a_adr <= 32'hZ;
        a_cyc <= 0;
        @(posedge ck);

        // dev A request
        a_adr <= 32'h11111111;
        a_cyc <= 1;
        wait (a_ack);
        tb_assert(a_rdt == a_adr);
        @(posedge ck);
        a_adr <= 32'hZ;
        a_cyc <= 0;
        @(posedge ck);

        // dev B request
        b_adr <= 32'h22222222;
        b_cyc <= 1;
        wait (b_ack);
        tb_assert(b_rdt == b_adr);
        @(posedge ck);
        b_adr <= 32'hZ;
        b_cyc <= 0;
        @(posedge ck);

        // Simultaneous A B requests
        // A should get priority
        a_adr <= 32'h11111111;
        a_cyc <= 1;
        b_adr <= 32'h22222222;
        b_cyc <= 1;
        wait (a_ack);
        tb_assert(a_rdt == a_adr);
        @(posedge ck);
        a_adr <= 32'hZ;
        a_cyc <= 0;
        wait (b_ack);
        tb_assert(b_rdt == b_adr);
        @(posedge ck);
        b_adr <= 32'hZ;
        b_cyc <= 0;
        @(posedge ck);

        // B request while A is waiting
        a_adr <= 32'h11111111;
        a_cyc <= 1;
        @(posedge ck);
        b_adr <= 32'h22222222;
        b_cyc <= 1;
        wait (a_ack);
        tb_assert(a_rdt == a_adr);
        @(posedge ck);
        a_adr <= 32'hZ;
        a_cyc <= 0;
        wait (b_ack);
        tb_assert(b_rdt == b_adr);
        @(posedge ck);
        b_adr <= 32'hZ;
        b_cyc <= 0;
        @(posedge ck);

        // A request while B is waiting
        b_adr <= 32'h22222222;
        b_cyc <= 1;
        @(posedge ck);
        a_adr <= 32'h11111111;
        a_cyc <= 1;
        wait (b_ack);
        @(posedge ck);
        tb_assert(b_rdt == b_adr);
        b_adr <= 32'hZ;
        b_cyc <= 0;
        wait (a_ack);
        @(posedge ck);
        tb_assert(a_rdt == a_adr);
        a_adr <= 32'hZ;
        a_cyc <= 0;
        @(posedge ck);

    end

endmodule
