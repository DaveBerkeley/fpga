

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

    // Simulate External Clock Gen

    reg ext_rst = 1;
    wire ext_en;
    wire ext_sck;
    wire ext_ws;
    wire [5:0] ext_frame_posn;

    localparam DIVIDER = 16;

    i2s_clock #(.DIVIDER(DIVIDER))
    i2s_clock_ext (
        .ck(ck),
        .rst(ext_rst),
        .en(ext_en),
        .sck(ext_sck),
        .ws(ext_ws),
        .frame_posn(ext_frame_posn)
    );

    wire sck;
    wire ws;
    wire en;
    wire [5:0] frame_posn;
    wire external;

    i2s_dual #(.DIVIDER(DIVIDER))
    i2s_dual(
        .ck(ck),
        .rst(rst),
        .ext_sck(ext_sck),
        .ext_ws(ext_ws),
        .sck(sck),
        .ws(ws),
        .en(en),
        .frame_posn(frame_posn),
        .external(external)
    );

    integer i;

    initial begin

        $display("start i2s tests");

        wait(!rst);

        // Wait for a few frames
        wait(ws);
        wait(!ws);
        wait(ws);
        wait(!ws);

        // turn off EXT
        ext_rst <= 1;
        for (i = 0; i < 30; i = i + 1) begin
            @(posedge sck);
        end

        // turn on EXT
        ext_rst <= 0;
        tb_assert(!external);

        // Wait for a few frames
        wait(ws);
        wait(!ws);
        wait(ws);
        wait(!ws);
        wait(ws);
        wait(!ws);

        tb_assert(external);

        wait(ws);
        wait(!ws);

        // turn off EXT
        ext_rst <= 1;

        // Wait for a few frames
        wait(ws);
        wait(!ws);
        wait(ws);
        wait(!ws);
        wait(ws);
        wait(!ws);

        tb_assert(!external);

        // Wait for a few frames
        wait(ws);
        wait(!ws);
        wait(ws);
        wait(!ws);

        $display("done");
        $finish;
    end

endmodule
    
