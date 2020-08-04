
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

endmodule


