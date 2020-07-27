
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

   /*
    *
    */

module top (output wire TX);

    assign TX = 0;

    reg wb_clk = 0;

    always #7 wb_clk <= !wb_clk;

    reg wb_rst = 1;

    initial begin
        $dumpfile("serv.vcd");
        $dumpvars(0, top);

        @(posedge wb_clk);
        @(posedge wb_clk);
        @(posedge wb_clk);
        @(posedge wb_clk);
        @(posedge wb_clk);
        @(posedge wb_clk);

        wb_rst <= 0;
        
        #500000 $finish;
    end

    //  iBus arbitration

    reg  wb_ibus_cyc = 0;
    reg  [31:0] wb_ibus_adr = 0;
    wire wb_ibus_ack;
    wire [31:0] wb_ibus_rdt;

    reg  f_cyc = 0;
    reg  [31:0] f_adr = 0;
    wire f_ack;
    wire [31:0] f_rdt;

    wire s_cyc;
    wire  [31:0] s_adr;
    reg  s_ack = 0;
    reg  [31:0] s_rdt = 0;

    wire busy;

    bus_arb ibus_arb(
        .wb_clk(wb_clk),
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
        .busy(busy)
    );

    // TODO : simulate slow device
    always @(posedge wb_clk) begin
        if (s_cyc) begin
            s_ack <= 1;
            s_rdt <= s_adr;
        end
        if (s_ack) begin
            s_ack <= 0;
            s_rdt <= 0;
        end
    end    

    reg [31:0] ibus_data;
    reg [31:0] fbus_data;

    always @(posedge wb_clk) begin
        if (f_ack) begin
            f_cyc <= 0;
            f_adr <= 32'hZ;
        end
    end

    always @(posedge wb_clk) begin
        if (wb_ibus_ack) begin
            wb_ibus_cyc <= 0;
            wb_ibus_adr <= 32'hZ;
        end
    end

    task ifetch(input [31:0] addr);

        begin
            wb_ibus_cyc <= 1;
            wb_ibus_adr <= addr;
            wait (wb_ibus_ack);
            // latch the data
            ibus_data <= wb_ibus_rdt;
            @(posedge wb_clk);
        end

    endtask

    task ffetch(input [31:0] addr);

        begin
            f_cyc <= 1;
            f_adr <= addr;
            wait (f_ack);
            // latch the data
            fbus_data <= f_rdt;
            @(posedge wb_clk);
        end

    endtask

    task die;

        begin
            @(posedge wb_clk);
            @(posedge wb_clk);
            @(posedge wb_clk);
            @(posedge wb_clk);
            @(posedge wb_clk);
            $finish;
        end

    endtask

    initial begin
        wait(!wb_rst);
        @(posedge wb_clk);

        // fetch in ibus
        ifetch(32'h100000);
        tb_assert(ibus_data == 32'h100000);

        wait(!busy);

        // fetch on fbus
        ffetch(32'h123456);
        tb_assert(fbus_data == 32'h123456);

        wait(!busy);
        
        // fetch both simultaneous : A should go first
        wb_ibus_cyc <= 1;
        wb_ibus_adr <= 32'hfaceface;
        f_cyc <= 1;
        f_adr <= 32'hcafecafe;

        wait(wb_ibus_ack);
        tb_assert(wb_ibus_rdt == 32'hfaceface);
        wait(f_ack);
        tb_assert(f_rdt == 32'hcafecafe);
        @(posedge wb_clk);

        wait(!busy);

        // start A, then make B req while busy
        wb_ibus_cyc <= 1;
        wb_ibus_adr <= 32'h34343434;
        @(posedge wb_clk);
        
        f_cyc <= 1;
        f_adr <= 32'h34563456;
        wait(wb_ibus_ack);
        tb_assert(wb_ibus_rdt == 32'h34343434);
        wait(f_ack);
        tb_assert(f_rdt == 32'h34563456);
        @(posedge wb_clk);
        @(posedge wb_clk);

        wait(!busy);

        // start B, then make A req while busy
        f_cyc <= 1;
        f_adr <= 32'hcafecafe;
        @(posedge wb_clk);
        wb_ibus_cyc <= 1;
        wb_ibus_adr <= 32'hfaceface;
        wait(f_ack);
        tb_assert(f_rdt == 32'hcafecafe);
        wait(wb_ibus_ack);
        tb_assert(wb_ibus_rdt == 32'hfaceface);

        //$finish;
    end

endmodule

