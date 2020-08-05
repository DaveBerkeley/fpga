
`default_nettype none
`timescale 1ns / 100ps

module tb ();

    initial begin
        $dumpfile("dsp.vcd");
        $dumpvars(0, tb);
        #5000000 $finish;
    end

    reg ck = 0;

    always #42 ck <= !ck;

    localparam WORDS = 512;
    localparam WIDTH = $clog2(WORDS);

    wire wb_clk;
    reg wb_rst = 0;

    assign wb_clk = ck;

    wire x_cyc;
    wire x_we;
    wire [3:0] x_sel;
    wire [31:0] x_adr;
    wire [31:0] x_dat;
    wire x_ack;
    wire [31:0] x_rdt;

    // Simulate a memory device ACKing on xbus

    reg x_busy = 0;

    always @(posedge wb_clk) begin
        if (x_cyc & !x_ack) begin
            x_busy <= 1;
        end
        if (x_busy) begin
            x_busy <= 0;
        end
    end

    assign x_ack = x_busy & x_cyc;

    sp_ram #(.WORDS(WORDS)) sp_ram (   
        .ck(wb_clk),
        .cyc(x_cyc),
        .we(x_we),
        .sel(x_sel),
        .addr(x_adr),
        .wdata(x_dat),
        .rdata(x_rdt)
    );

    assign x_ack = x_busy & x_cyc;

    reg  a_cyc = 0;
    reg  a_we = 0;
    reg  [3:0] a_sel = 0;
    reg  [31:0] a_adr = 0;
    reg  [31:0] a_dat = 0;

    reg  b_cyc = 0;
    reg  b_we = 0;
    reg  [3:0] b_sel = 0;
    reg  [31:0] b_adr = 0;
    reg  [31:0] b_dat = 0;

    wire a_ack;
    wire [31:0] a_rdt;
    wire b_ack;
    wire [31:0] b_rdt;

    ram_arb #(.WIDTH(32))
    ram_arb (
        .wb_clk(wb_clk),
        .wb_rst(wb_rst),
        .a_cyc(a_cyc),
        .a_we(a_we),
        .a_sel(a_sel),
        .a_adr(a_adr),
        .a_dat(a_dat),
        .a_ack(a_ack),
        .a_rdt(a_rdt),
        .b_cyc(b_cyc),
        .b_we(b_we),
        .b_sel(b_sel),
        .b_adr(b_adr),
        .b_dat(b_dat),
        .b_ack(b_ack),
        .b_rdt(b_rdt),
        .x_cyc(x_cyc),
        .x_we(x_we),
        .x_sel(x_sel),
        .x_adr(x_adr),
        .x_dat(x_dat),
        .x_ack(x_ack),
        .x_rdt(x_rdt)
    );

    always @(posedge wb_clk) begin
        if (a_ack) begin
            a_cyc <= 0;
            a_adr <= 32'hZ;
            a_dat <= 32'hZ;
            a_we <= 0;
            a_sel <= 0;
        end
        if (b_ack) begin
            b_cyc <= 0;
            b_adr <= 32'hZ;
            b_dat <= 32'hZ;
            b_we <= 0;
            b_sel <= 0;
        end
    end

    task write_a(input [31:0] addr, input [31:0] data, input [3:0] sel);

        begin
            a_adr <= addr;
            a_dat <= data;
            a_we <= 1;
            a_sel <= sel;
            a_cyc <= 1;
        end

    endtask

    task read_a(input [31:0] addr, input [3:0] sel);

        begin
            a_adr <= addr;
            a_we <= 0;
            a_cyc <= 1;
        end

    endtask

    task write_b(input [31:0] addr, input [31:0] data, input [3:0] sel);

        begin
            b_adr <= addr;
            b_dat <= data;
            b_we <= 1;
            b_sel <= sel;
            b_cyc <= 1;
        end

    endtask

    task read_b(input [31:0] addr, input [3:0] sel);

        begin
            b_adr <= addr;
            b_we <= 0;
            b_cyc <= 1;
        end

    endtask

    initial begin

        wb_rst <= 1;
        @(posedge wb_clk);
        @(posedge wb_clk);
        wb_rst <= 0;
        @(posedge wb_clk);

        write_a(32'h8000_0020, 32'h1234_3456, 4'b1111);
        @(posedge wb_clk);

        // check that x_bus sees the signals
        tb_assert(x_cyc);
        tb_assert(x_we);
        tb_assert(x_sel == 4'b1111);
        tb_assert(x_adr == 32'h8000_0020);
        tb_assert(x_dat == 32'h1234_3456);

        // wait for a_ack : x_bus still valid
        wait(a_ack);
        tb_assert(x_cyc);
        tb_assert(x_we);
        tb_assert(x_sel == 4'b1111);
        tb_assert(x_adr == 32'h8000_0020);
        tb_assert(x_dat == 32'h1234_3456);

        wait(!a_cyc);
        @(posedge wb_clk);
        tb_assert(x_ack == 0);
        tb_assert(x_cyc == 0);
        tb_assert(x_we == 0);
        tb_assert(x_sel == 0);
        tb_assert(x_adr == 0);
        tb_assert(x_dat == 0);

        write_b(32'h8000_0010, 32'hcafe_cafe, 4'b1111);
        @(posedge wb_clk);
        // check that x_bus sees the signals
        tb_assert(x_cyc);
        tb_assert(x_we);
        tb_assert(x_sel == 4'b1111);
        tb_assert(x_adr == 32'h8000_0010);
        tb_assert(x_dat == 32'hcafe_cafe);

        // wait for b_ack : x_bus still valid
        wait(b_ack);
        tb_assert(x_cyc);
        tb_assert(x_we);
        tb_assert(x_sel == 4'b1111);
        tb_assert(x_adr == 32'h8000_0010);
        tb_assert(x_dat == 32'hcafe_cafe);

        wait(!b_cyc);
        @(posedge wb_clk);
        tb_assert(x_ack == 0);
        tb_assert(x_cyc == 0);
        tb_assert(x_we == 0);
        tb_assert(x_sel == 0);
        tb_assert(x_adr == 0);
        tb_assert(x_dat == 0);

        read_a(32'h8000_0020, 4'b1111);
        wait(!a_cyc);
        @(posedge wb_clk);


    end

endmodule

