

`default_nettype none
`timescale 1ns / 100ps

module tb ();

    initial begin
        $dumpfile("dsp.vcd");
        $dumpvars(0, tb);
    end

    reg ck = 0;

    always #42 ck <= !ck;

    wire rst;

    reset #(.LENGTH(4)) reset (.ck(ck), .rst_req(1'b0), .rst(rst));

    //  Local Clock Gen

    wire gen_en;
    wire gen_sck;
    wire gen_ws;
    wire [5:0] gen_frame_posn;

    i2s_clock #(.DIVIDER(12))
    i2s_clock (
        .ck(ck),
        .rst(rst),
        .en(gen_en),
        .sck(gen_sck),
        .ws(gen_ws),
        .frame_posn(gen_frame_posn)
    );

    // Simulate External Clock Gen

    reg ext_rst = 1;
    wire ext_en;
    wire ext_sck;
    wire ext_ws;
    wire [5:0] ext_frame_posn;

    i2s_clock #(.DIVIDER(12))
    i2s_clock_ext (
        .ck(ck),
        .rst(ext_rst),
        .en(ext_en),
        .sck(ext_sck),
        .ws(ext_ws),
        .frame_posn(ext_frame_posn)
    );

    //  Attempt to lock to external clock

    wire sec_en;
    wire [5:0] sec_frame_posn;

    i2s_secondary #(.WIDTH(5))
    i2s_secondary(
        .ck(ck),
        .sck(ext_sck),
        .ws(ext_ws),
        .en(sec_en),
        .frame_posn(sec_frame_posn)
    );

    wire external;

    i2s_detect #(.WIDTH(3))
    i2s_detect (
        .ck(ck),
        .ext_en(ext_en),
        .gen_en(gen_en),
        .external(external)
    );

    wire dual_sck;
    wire dual_ws;
    wire dual_en;
    wire [5:0] dual_frame_posn;

    i2s_dual #(.DIVIDER(16))
    i2s_dual(
        .ck(ck),
        .rst(rst),
        .ext_sck(ext_sck),
        .ext_ws(ext_ws),
        .sck(dual_sck),
        .ws(dual_ws),
        .en(dual_en),
        .frame_posn(dual_frame_posn)
    );

    initial begin

        $display("start i2s tests");

        wait(!rst);

        // turn off EXT
        ext_rst <= 1;

        // Wait for a few frames
        wait(gen_ws);
        wait(!gen_ws);
        wait(gen_ws);
        wait(!gen_ws);
        wait(gen_ws);
        wait(!gen_ws);
        wait(gen_ws);
        wait(!gen_ws);

        tb_assert(!external);

        // turn on EXT
        ext_rst <= 0;

        // Wait for a few frames
        wait(gen_ws);
        wait(!gen_ws);
        wait(gen_ws);
        wait(!gen_ws);

        tb_assert(external);

        // turn off EXT
        ext_rst <= 1;

        // Wait for a few frames
        wait(gen_ws);
        wait(!gen_ws);
        wait(gen_ws);
        wait(!gen_ws);

        tb_assert(!external);

        // Wait for a few frames
        wait(gen_ws);
        wait(!gen_ws);
        wait(gen_ws);
        wait(!gen_ws);

        $display("done");
        $finish;
    end

endmodule
    
