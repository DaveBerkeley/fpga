

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

    reset #(.LENGTH(20)) reset (.ck(ck), .rst_req(1'b0), .rst(rst));

    wire sample;
    reg [5:0] frame_posn = 0;
    wire sd;
    wire [23:0] left;
    wire [23:0] right;
    wire [15:0] left_16;
    wire [15:0] right_16;

    i2s_rx #(.BITS(24))
    i2s_rx (
        .ck(ck),
        .sample(sample),
        .frame_posn(frame_posn),
        .sd(sd),
        .left(left),
        .right(right)
    );

    i2s_rx #(.BITS(16))
    i2s_rx_16 (
        .ck(ck),
        .sample(sample),
        .frame_posn(frame_posn),
        .sd(sd),
        .left(left_16),
        .right(right_16)
    );

    reg [63:0] tx_shift = 0;

    reg [3:0] prescale = -1;
    wire tx_en, frame_en;

    assign frame_en = prescale == 6;
    assign tx_en = prescale == 8;
    assign sample = prescale == 12;

    always @(posedge ck) begin

        if(rst) begin
            prescale <= 0;
            tx_shift <= 0;
        end else begin

            prescale <= prescale + 1;
            if (frame_en) begin
                frame_posn <= frame_posn + 1;
            end
    
            if (frame_en) begin
                tx_shift <= { tx_shift[62:0], 1'b0 };
            end

        end

    end

    assign sd = tx_shift[63];

    task send(input [23:0] l, input [23:0] r);

        begin
            wait((frame_posn == 1) && tx_en);
            tx_shift <= { l, 8'h0, r, 8'h0 };
            wait(frame_posn == 2);
        end

    endtask

    initial begin

        $display("start i2s rx tests");

        wait(!rst);
        @(posedge ck);

        //
        wait(frame_posn == 5);
        send(24'hf0f0f0, 24'hcafedb);

        wait(frame_posn == 0);
        tb_assert(left == 24'hf0f0f0);
        tb_assert(right == 24'hcafedb);
        tb_assert(left_16 == 24'hf0f0);
        tb_assert(right_16 == 24'hcafe);

        //
        wait(frame_posn == 5);
        send(24'h123456, 24'hFFFFFF);

        wait(frame_posn == 0);
        tb_assert(left == 24'h123456);
        tb_assert(right == 24'hFFFFFF);
        tb_assert(left_16 == 24'h1234);
        tb_assert(right_16 == 24'hFFFF);

        //
        wait(frame_posn == 5);
        send(24'h000000, 24'haaaaaa);

        wait(frame_posn == 0);
        tb_assert(left == 24'h000000);
        tb_assert(right == 24'haaaaaa);
        tb_assert(left_16 == 24'h0000);
        tb_assert(right_16 == 24'haaaa);

        //
        wait(frame_posn == 5);
        send(24'h555555, 24'h123456);

        wait(frame_posn == 0);
        tb_assert(left == 24'h555555);
        tb_assert(right == 24'h123456);
        tb_assert(left_16 == 24'h5555);
        tb_assert(right_16 == 24'h1234);

        $display("done");
        $finish;
    end

endmodule
    
