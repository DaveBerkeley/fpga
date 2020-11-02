

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

    reg [31:0] tx_shift_32 = 0;
    wire [15:0] left_32;
    wire [15:0] right_32;
    wire sd_32;
    assign sd_32 = tx_shift_32[31];

    always @(posedge ck) begin

        if (rst) begin
            tx_shift_32 <= 0;
        end else begin
            if (frame_en) begin
                tx_shift_32 <= { tx_shift_32[30:0], 1'b0 };
            end
        end

    end

    i2s_rx #(.BITS(16), .CLOCKS(32))
    i2s_rx_32 (
        .ck(ck),
        .sample(sample),
        .frame_posn(frame_posn),
        .sd(sd_32),
        .left(left_32),
        .right(right_32)
    );

    task send_32(input [15:0] l, input [15:0] r);

        begin
            wait((frame_posn == 1) && tx_en);
            tx_shift_32 <= { l, r };
            wait(frame_posn == 2);
        end

    endtask

    wire [4:0] frame;
    assign frame = frame_posn[4:0];

    initial begin

        $display("start i2s 32-bit rx tests");

        wait(!rst);
        @(posedge ck);

        send_32(16'hface, 16'h1234);
        wait(frame == 18);
        tb_assert(left_32 == 16'hface);
        wait(frame == 2);
        tb_assert(right_32 == 16'h1234);

        send_32(16'hffff, 16'h0000);
        wait(frame == 18);
        tb_assert(left_32 == 16'hffff);
        wait(frame == 2);
        tb_assert(right_32 == 16'h0000);

        send_32(16'h0000, 16'hffff);
        wait(frame == 18);
        tb_assert(left_32 == 16'h0000);
        wait(frame == 2);
        tb_assert(right_32 == 16'hffff);

        send_32(16'haaaa, 16'h5555);
        wait(frame == 18);
        tb_assert(left_32 == 16'haaaa);
        wait(frame == 2);
        tb_assert(right_32 == 16'h5555);
    end

    reg [15:0] left_tx = 0;
    reg [15:0] right_tx = 0;
    wire tx;

    i2s_tx #(.CLOCKS(64))
        tx_hw (.ck(ck),
        .en(sample),
        .frame_posn(frame_posn),
        .left(left_tx),
        .right(right_tx),
        .sd(tx)
    );

    task wait_sample(input signal);

        begin
            @(posedge ck);
            wait(sample);
            @(posedge ck);
            wait(!sample);
            @(posedge ck);
        end

    endtask

    integer i;

    initial begin

        $display("start i2s tx tests");

        left_tx <= 16'h1234;
        right_tx <= 16'habcd;

        wait(!rst);
        @(posedge ck);

        // wait for start of next frame
        wait(frame_posn == 'h0);
        @(posedge ck);
        wait(frame_posn == 'h1);
        @(posedge ck);
        // wait for start of next frame
        wait(frame_posn == 'h0);
        // first slot is end of prev frame
        wait_sample(sample);

        // check the tx bits
        // 1
        wait_sample(sample);
        tb_assert(tx == 1'b0);
        wait_sample(sample);
        tb_assert(tx == 1'b0);
        wait_sample(sample);
        tb_assert(tx == 1'b0);
        wait_sample(sample);
        tb_assert(tx == 1'b1);
        // 2
        wait_sample(sample);
        tb_assert(tx == 1'b0);
        wait_sample(sample);
        tb_assert(tx == 1'b0);
        wait_sample(sample);
        tb_assert(tx == 1'b1);
        wait_sample(sample);
        tb_assert(tx == 1'b0);
        // 3
        wait_sample(sample);
        tb_assert(tx == 1'b0);
        wait_sample(sample);
        tb_assert(tx == 1'b0);
        wait_sample(sample);
        tb_assert(tx == 1'b1);
        wait_sample(sample);
        tb_assert(tx == 1'b1);
        // 4
        wait_sample(sample);
        tb_assert(tx == 1'b0);
        wait_sample(sample);
        tb_assert(tx == 1'b1);
        wait_sample(sample);
        tb_assert(tx == 1'b0);
        wait_sample(sample);
        tb_assert(tx == 1'b0);

        // The 64-version now has 16-bits of zeros
        for (i = 0; i < 16; i = i + 1) begin
            wait_sample(sample);
            tb_assert(tx == 1'b0);
        end

        // A
        wait_sample(sample);
        tb_assert(tx == 1'b1);
        wait_sample(sample);
        tb_assert(tx == 1'b0);
        wait_sample(sample);
        tb_assert(tx == 1'b1);
        wait_sample(sample);
        tb_assert(tx == 1'b0);
        // B
        wait_sample(sample);
        tb_assert(tx == 1'b1);
        wait_sample(sample);
        tb_assert(tx == 1'b0);
        wait_sample(sample);
        tb_assert(tx == 1'b1);
        wait_sample(sample);
        tb_assert(tx == 1'b1);
        // C
        wait_sample(sample);
        tb_assert(tx == 1'b1);
        wait_sample(sample);
        tb_assert(tx == 1'b1);
        wait_sample(sample);
        tb_assert(tx == 1'b0);
        wait_sample(sample);
        tb_assert(tx == 1'b0);
        // D
        wait_sample(sample);
        tb_assert(tx == 1'b1);
        wait_sample(sample);
        tb_assert(tx == 1'b1);
        wait_sample(sample);
        tb_assert(tx == 1'b0);
        wait_sample(sample);
        tb_assert(tx == 1'b1);

        // The 64-version now has 16-bits of zeros
        for (i = 0; i < 16; i = i + 1) begin
            wait_sample(sample);
            tb_assert(tx == 1'b0);
        end

    end

    reg [15:0] left_tx_32 = 0;
    reg [15:0] right_tx_32 = 0;
    wire tx_32;

    i2s_tx #(.CLOCKS(32))
        tx_hw_32 (.ck(ck),
        .en(sample),
        .frame_posn(frame_posn),
        .left(left_tx_32),
        .right(right_tx_32),
        .sd(tx_32)
    );

    initial begin

        $display("start i2s tx 32 tests");

        left_tx_32 <= 16'hdead;
        right_tx_32 <= 16'hface;

        wait(!rst);
        @(posedge ck);

        // wait for start of next frame
        wait(frame_posn == 'h0);
        @(posedge ck);
        wait(frame_posn == 'h1);
        @(posedge ck);
        // wait for start of next frame
        wait(frame_posn == 'h0);
        // first slot is end of prev frame
        wait_sample(sample);

        // D
        wait_sample(sample);
        tb_assert(tx_32 == 1'b1);
        wait_sample(sample);
        tb_assert(tx_32 == 1'b1);
        wait_sample(sample);
        tb_assert(tx_32 == 1'b0);
        wait_sample(sample);
        tb_assert(tx_32 == 1'b1);
        // E
        wait_sample(sample);
        tb_assert(tx_32 == 1'b1);
        wait_sample(sample);
        tb_assert(tx_32 == 1'b1);
        wait_sample(sample);
        tb_assert(tx_32 == 1'b1);
        wait_sample(sample);
        tb_assert(tx_32 == 1'b0);
        // A
        wait_sample(sample);
        tb_assert(tx_32 == 1'b1);
        wait_sample(sample);
        tb_assert(tx_32 == 1'b0);
        wait_sample(sample);
        tb_assert(tx_32 == 1'b1);
        wait_sample(sample);
        tb_assert(tx_32 == 1'b0);
        // D
        wait_sample(sample);
        tb_assert(tx_32 == 1'b1);
        wait_sample(sample);
        tb_assert(tx_32 == 1'b1);
        wait_sample(sample);
        tb_assert(tx_32 == 1'b0);
        wait_sample(sample);
        tb_assert(tx_32 == 1'b1);
        // F
        wait_sample(sample);
        tb_assert(tx_32 == 1'b1);
        wait_sample(sample);
        tb_assert(tx_32 == 1'b1);
        wait_sample(sample);
        tb_assert(tx_32 == 1'b1);
        wait_sample(sample);
        tb_assert(tx_32 == 1'b1);
        // A
        wait_sample(sample);
        tb_assert(tx_32 == 1'b1);
        wait_sample(sample);
        tb_assert(tx_32 == 1'b0);
        wait_sample(sample);
        tb_assert(tx_32 == 1'b1);
        wait_sample(sample);
        tb_assert(tx_32 == 1'b0);
        // C
        wait_sample(sample);
        tb_assert(tx_32 == 1'b1);
        wait_sample(sample);
        tb_assert(tx_32 == 1'b1);
        wait_sample(sample);
        tb_assert(tx_32 == 1'b0);
        wait_sample(sample);
        tb_assert(tx_32 == 1'b0);
        // E
        wait_sample(sample);
        tb_assert(tx_32 == 1'b1);
        wait_sample(sample);
        tb_assert(tx_32 == 1'b1);
        wait_sample(sample);
        tb_assert(tx_32 == 1'b1);
        wait_sample(sample);
        tb_assert(tx_32 == 1'b0);

        // start again ...
        // D
        wait_sample(sample);
        tb_assert(tx_32 == 1'b1);
        wait_sample(sample);
        tb_assert(tx_32 == 1'b1);
        wait_sample(sample);
        tb_assert(tx_32 == 1'b0);
        wait_sample(sample);
        tb_assert(tx_32 == 1'b1);

    end

endmodule
    

