
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

    reg  rst = 0;
    reg  peak_en = 0;
    reg  decay_en = 0;
    reg  [15:0] in = 0;
    wire [15:0] out;

    spl spl (.ck(ck), .rst(rst), .peak_en(peak_en), .decay_en(decay_en), .in(in), .out(out));

    integer i;

    //  Test spl module

    initial begin
        $display("test spl()");
        @(posedge ck);

        peak_en = 0;
        decay_en = 0;
        in <= 16'h4000;
        @(posedge ck);

        tb_assert(out == 0);

        peak_en <= 1;
        @(posedge ck);
        peak_en <= 0;
        @(posedge ck);
        tb_assert(out == 16'h4000);

        // Check countdown to 0000
        decay_en = 1;
        @(posedge ck);
        @(posedge ck);
        tb_assert(out == 16'h3fff);
        @(posedge ck);
        tb_assert(out == 16'h3ffe);
        @(posedge ck);
        tb_assert(out == 16'h3ffd);
        @(posedge ck);
        tb_assert(out == 16'h3ffc);

        wait(out == 16'h0002);
        decay_en = 0;
        @(posedge ck);
        @(posedge ck);
        @(posedge ck);
        @(posedge ck);
        tb_assert(out == 16'h0002);
        @(posedge ck);
        decay_en = 1;
        @(posedge ck);
        tb_assert(out == 16'h0001);
        @(posedge ck);
        tb_assert(out == 16'h0000);
        @(posedge ck);
        tb_assert(out == 16'h0000);
        @(posedge ck);
        tb_assert(out == 16'h0000);

        decay_en = 0;
        in <= 0;
        @(posedge ck);
        @(posedge ck);
        peak_en <= 1;

        // Check peak hold
        for (i = 0; i < 16'h8000; i = i + 10) begin
            in <= i;
            @(posedge ck);
            @(posedge ck);
            @(posedge ck);
            tb_assert(out == i);
        end

        in <= 0;
        peak_en <= 0;

        // check the reset
        rst <= 1;
        @(posedge ck);
        @(posedge ck);
        tb_assert(out == 0);
        rst <= 0;
        @(posedge ck);
        @(posedge ck);

        // check negative numbers
        in <= 0;
        @(posedge ck);
        @(posedge ck);
        peak_en <= 1;

        for (i = 0; i < 16'h8000; i = i + 10) begin
            // load 2s complement
            in <= 1 + ~i;
            @(posedge ck);
            @(posedge ck);
            @(posedge ck);
            tb_assert(out == i);

            in <= i;
            @(posedge ck);
            @(posedge ck);
            @(posedge ck);
            tb_assert(out == i);

        end

        @(posedge ck);
        @(posedge ck);
        @(posedge ck);
        $finish;
    end

    //  Test spl_xfer module

    reg run = 0;
    reg rst_2 = 0;
    reg [15:0] data_in = 0;
    wire [15:0] data_out;
    wire [2:0] addr;
    wire we;
    wire done;
    wire busy;

    spl_xfer #(.WIDTH(16), .ADDR_W(3))
    spl_xfer (
        .ck(ck),
        .rst(rst_2),
        .run(run),
        .data_in(data_in),
        .data_out(data_out),
        .addr(addr),
        .we(we),
        .done(done),
        .busy(busy)
    );

    initial begin

        rst_2 <= 1;
        @(posedge ck);
        @(posedge ck);

        rst_2 <= 0;
        @(posedge ck);
        @(posedge ck);
        tb_assert(!done);
        tb_assert(!busy);
        tb_assert(!we);

        run <= 1;
        data_in <= 16'h1234;
        @(posedge ck);
        @(posedge ck);
        tb_assert(data_out == data_in);
        tb_assert(addr == 0);
        tb_assert(!done);
        tb_assert(busy);
        tb_assert(we);

        data_in <= 16'habcd;
        @(posedge ck);
        tb_assert(data_out == data_in);
        tb_assert(addr == 1);
        tb_assert(!done);
        tb_assert(busy);
        tb_assert(we);

        data_in <= 16'hcafe;
        @(posedge ck);
        tb_assert(data_out == data_in);
        tb_assert(addr == 2);
        tb_assert(!done);
        tb_assert(busy);
        tb_assert(we);

        data_in <= 16'hface;
        @(posedge ck);
        tb_assert(data_out == data_in);
        tb_assert(addr == 3);
        tb_assert(!done);
        tb_assert(busy);
        tb_assert(we);

        data_in <= 16'h1111;
        @(posedge ck);
        tb_assert(data_out == data_in);
        tb_assert(addr == 4);
        tb_assert(!done);
        tb_assert(busy);
        tb_assert(we);

        data_in <= 16'h2222;
        @(posedge ck);
        tb_assert(data_out == data_in);
        tb_assert(addr == 5);
        tb_assert(!done);
        tb_assert(busy);
        tb_assert(we);

        data_in <= 16'h4444;
        @(posedge ck);
        tb_assert(data_out == data_in);
        tb_assert(addr == 6);
        tb_assert(!done);
        tb_assert(busy);
        tb_assert(we);

        data_in <= 16'h8888;
        @(posedge ck);
        tb_assert(data_out == data_in);
        tb_assert(addr == 7);
        tb_assert(!done);
        tb_assert(busy);
        tb_assert(we);

        data_in <= 16'h1234;
        @(posedge ck);
        tb_assert(data_out == 0);
        tb_assert(addr == 0);
        tb_assert(done);
        tb_assert(!busy);
        tb_assert(!we);

    end 

endmodule


