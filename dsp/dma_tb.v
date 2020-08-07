
`default_nettype none
`timescale 1ns / 100ps

module tb ();

    initial begin
        $dumpfile("dsp.vcd");
        $dumpvars(0, tb);
        #500000 $finish;
    end

    reg wb_clk = 0;
    reg wb_rst = 1;


    always #42 wb_clk <= !wb_clk;

    reg wb_dbus_cyc = 0;
    reg wb_dbus_we = 0;
    reg [31:0] wb_dbus_adr = 32'hZ;
    reg [31:0] wb_dbus_dat = 32'hZ;
    wire [31:0] dbus_rdt;
    wire dbus_ack;

    wire dma_cyc;
    wire dma_we;
    wire [3:0] dma_sel;
    wire [31:0] dma_adr;
    wire [31:0] dma_dat;
    reg dma_ack = 0;
    wire [31:0] dma_rdt;

    reg xfer_block = 0;
    wire block_done;
    wire xfer_done;

    wire xfer_re;
    wire [15:0] xfer_adr;
    wire [15:0] xfer_dat;

    dma #(.ADDR(8'h65), .WIDTH(8)) dma(
        .wb_clk(wb_clk),
        .wb_rst(wb_rst),
        .wb_dbus_cyc(wb_dbus_cyc),
        .wb_dbus_we(wb_dbus_we),
        .wb_dbus_adr(wb_dbus_adr),
        .wb_dbus_dat(wb_dbus_dat),
        .dbus_rdt(dbus_rdt),
        .dbus_ack(dbus_ack),
        .xfer_block(xfer_block),
        .xfer_adr(xfer_adr),
        .xfer_dat(xfer_dat),
        .xfer_re(xfer_re),
        .block_done(block_done),
        .xfer_done(xfer_done),
        .dma_cyc(dma_cyc),
        .dma_we(dma_we),
        .dma_sel(dma_sel),
        .dma_adr(dma_adr),
        .dma_dat(dma_dat),
        .dma_ack(dma_ack),
        .dma_rdt(dma_rdt)
    );

    task read(input [31:0] addr);

        begin

            wb_dbus_cyc <= 1;
            wb_dbus_adr <= addr;

        end

    endtask

    task write(input [31:0] addr, input [31:0] data);

        begin

            wb_dbus_cyc <= 1;
            wb_dbus_adr <= addr;
            wb_dbus_we <= 1;
            wb_dbus_dat <= data;

        end

    endtask

    always @(posedge wb_clk) begin
        if (dbus_ack) begin
            wb_dbus_cyc <= 0;
            wb_dbus_we <= 0;
            wb_dbus_adr <= 32'hZ;
            wb_dbus_dat <= 32'hZ;
        end
    end

    // Handle ACK for the target RAM
    always @(posedge wb_clk) begin
        if (dma_cyc) begin
            dma_ack <= 1;
        end
        if (dma_ack) begin
            dma_ack <= 0;
        end
    end

    reg [31:0] rd_data;

    // Latch any data reads on dbus
    always @(posedge wb_clk) begin
        if (dbus_ack) begin
            rd_data <= dbus_rdt; 
        end
    end

    // Check rdt is never non-zero outside ack
    always @(posedge wb_clk) begin
        if (!dbus_ack) begin
            //tb_assert(dbus_rdt == 0);
        end
    end
    

    assign xfer_dat = xfer_re ? (16'h1111 << xfer_adr) : 0;

    localparam REG_ADDR   = 32'h65000000;
    localparam REG_STEPS  = 32'h65000004;
    localparam REG_CYCLES = 32'h65000008;
    localparam REG_BLOCKS = 32'h6500000c;
    localparam REG_START  = 32'h65000010;
    localparam REG_END    = 32'h65000014;
    localparam REG_STATUS = 32'h65000018;

    integer i;

    initial begin

        @(posedge wb_clk);
        @(posedge wb_clk);
        wb_rst <= 0;
        @(posedge wb_clk);
        @(posedge wb_clk);

        write(REG_ADDR,   32'h00010000);
        @(posedge wb_clk);
        wait(!wb_dbus_cyc);
        @(posedge wb_clk);

        write(REG_STEPS,  32'h00001000);
        @(posedge wb_clk);
        wait(!wb_dbus_cyc);
        @(posedge wb_clk);

        write(REG_CYCLES, 32'h00000010);
        @(posedge wb_clk);
        wait(!wb_dbus_cyc);
        @(posedge wb_clk);

        write(REG_BLOCKS, 32'h8);
        @(posedge wb_clk);
        wait(!wb_dbus_cyc);
        @(posedge wb_clk);

        write(REG_START,  32'h1);
        @(posedge wb_clk);
        wait(!wb_dbus_cyc);
        @(posedge wb_clk);
        @(posedge wb_clk);

        for (i = 0; i < 16; i = i + 1) begin

            @(posedge wb_clk);
            @(posedge wb_clk);
            @(posedge wb_clk);

            xfer_block <= 1;
            @(posedge wb_clk);
            xfer_block <= 0;
            @(posedge wb_clk);

            wait(block_done);

        end

        write(REG_END,  32'h1);
        @(posedge wb_clk);
        wait(!wb_dbus_cyc);
        @(posedge wb_clk);
        @(posedge wb_clk);
        @(posedge wb_clk);
        @(posedge wb_clk);

        write(REG_START,  32'h1);
        @(posedge wb_clk);
        wait(!wb_dbus_cyc);
        @(posedge wb_clk);

        for (i = 0; i < 16; i = i + 1) begin

            @(posedge wb_clk);
            @(posedge wb_clk);
            @(posedge wb_clk);

            xfer_block <= 1;
            @(posedge wb_clk);
            xfer_block <= 0;
            @(posedge wb_clk);

            wait(block_done);

        end

        wait(xfer_done);

        // Test reading the control registers

        read(REG_ADDR);
        wait(dbus_ack);
        wait(!dbus_ack);
        tb_assert(rd_data == 32'h10000);
        @(posedge wb_clk);

        read(REG_STEPS);
        wait(dbus_ack);
        wait(!dbus_ack);
        tb_assert(rd_data == 32'h1000);
        @(posedge wb_clk);

        read(REG_CYCLES);
        wait(dbus_ack);
        wait(!dbus_ack);
        tb_assert(rd_data == 32'h10);
        @(posedge wb_clk);

        read(REG_BLOCKS);
        wait(dbus_ack);
        wait(!dbus_ack);
        tb_assert(rd_data == 32'h8);
        @(posedge wb_clk);

        read(REG_STATUS);
        wait(dbus_ack);
        wait(!dbus_ack);
        tb_assert(rd_data == 32'h3); // block/xfer done
        @(posedge wb_clk);

        $display("done");

    end


endmodule
