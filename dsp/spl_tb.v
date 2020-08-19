
`default_nettype none
`timescale 1ns / 100ps

   /*
    *
    */

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

    reg [15:0] level_in = 0;
    reg level_en = 0;
    wire [3:0] level_code;
    wire ready;

    level #(.IN_W(16)) level(.ck(ck), .en(level_en), .in(level_in), .level(level_code), .ready(ready));

    integer i;

    task set_level(input [15:0] value);
        begin
            @(posedge ck);
            level_en <= 1;
            level_in <= value;
            @(posedge ck);
            level_en <= 0;
            level_in <= 16'hZ;
            @(posedge ck);
            wait(ready);
        end
    endtask

    //  Test level module
    initial begin

        set_level(16'b10zz_zzzz_zzzz_zzzz);
        tb_assert(level_code == 0);

        set_level(16'b110z_zzzz_zzzz_zzzz);
        tb_assert(level_code == 1);

        set_level(16'b1110_zzzz_zzzz_zzzz);
        tb_assert(level_code == 2);

        set_level(16'b1111_0zzz_zzzz_zzzz);
        tb_assert(level_code == 3);

        set_level(16'b1111_10zz_zzzz_zzzz);
        tb_assert(level_code == 4);

        set_level(16'b1111_110z_zzzz_zzzz);
        tb_assert(level_code == 5);

        set_level(16'b1111_1110_zzzz_zzzz);
        tb_assert(level_code == 6);

        set_level(16'b1111_1111_0zzz_zzzz);
        tb_assert(level_code == 7);

        set_level(16'b1111_1111_10zz_zzzz);
        tb_assert(level_code == 8);

        set_level(16'b1111_1111_110z_zzzz);
        tb_assert(level_code == 9);

        set_level(16'b1111_1111_1110_zzzz);
        tb_assert(level_code == 10);

        set_level(16'b1111_1111_1111_0zzz);
        tb_assert(level_code == 11);

        set_level(16'b1111_1111_1111_10zz);
        tb_assert(level_code == 12);

        set_level(16'b1111_1111_1111_110z);
        tb_assert(level_code == 13);

        set_level(16'b1111_1111_1111_1110);
        tb_assert(level_code == 14);

        set_level(16'b1111_1111_1111_1111);
        tb_assert(level_code == 15);

        set_level(16'b01zz_zzzz_zzzz_zzzz);
        tb_assert(level_code == 0);

        set_level(16'b001z_zzzz_zzzz_zzzz);
        tb_assert(level_code == 1);

        set_level(16'b0001_0zzz_zzzz_zzzz);
        tb_assert(level_code == 2);

        set_level(16'b0000_10zz_zzzz_zzzz);
        tb_assert(level_code == 3);

        set_level(16'b0000_01zz_zzzz_zzzz);
        tb_assert(level_code == 4);

        set_level(16'b0000_001z_zzzz_zzzz);
        tb_assert(level_code == 5);

        set_level(16'b0000_0001_zzzz_zzzz);
        tb_assert(level_code == 6);

        set_level(16'b0000_0000_1zzz_zzzz);
        tb_assert(level_code == 7);

        set_level(16'b0000_0000_01zz_zzzz);
        tb_assert(level_code == 8);

        set_level(16'b0000_0000_001z_zzzz);
        tb_assert(level_code == 9);

        set_level(16'b0000_0000_0001_zzzz);
        tb_assert(level_code == 10);

        set_level(16'b0000_0000_0000_1zzz);
        tb_assert(level_code == 11);

        set_level(16'b0000_0000_0000_01zz);
        tb_assert(level_code == 12);

        set_level(16'b0000_0000_0000_001z);
        tb_assert(level_code == 13);

        set_level(16'b0000_0000_0000_0001);
        tb_assert(level_code == 14);

        set_level(16'b0000_0000_0000_0000);
        tb_assert(level_code == 15);

    end

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

endmodule


