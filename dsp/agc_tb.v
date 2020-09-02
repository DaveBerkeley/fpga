
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

    //  Test shift

    reg [2:0] shift_by = 0;
    reg [23:0] shift_in = 0;
    wire [15:0] shift_out;

    shift #(.IN_W(24), .OUT_W(16))
    shift (
        .ck(ck),
        .shift(shift_by),
        .in(shift_in),
        .out(shift_out)
    );

    initial begin
        @(posedge ck);
        @(posedge ck);

        shift_by <= 3'b000;
        shift_in <= 24'h123456;
        @(posedge ck);
        tb_assert(shift_out == (16'hffff & (shift_in >> 8)));

        shift_by <= 3'b001;
        @(posedge ck);
        tb_assert(shift_out == (16'hffff & (shift_in >> 7)));

        shift_by <= 3'b010;
        @(posedge ck);
        tb_assert(shift_out == (16'hffff & (shift_in >> 6)));

        shift_by <= 3'b011;
        @(posedge ck);
        tb_assert(shift_out == (16'hffff & (shift_in >> 5)));

        shift_by <= 3'b100;
        @(posedge ck);
        tb_assert(shift_out == (16'hffff & (shift_in >> 4)));

        shift_by <= 3'b101;
        @(posedge ck);
        tb_assert(shift_out == (16'hffff & (shift_in >> 3)));

        shift_by <= 3'b110;
        @(posedge ck);
        tb_assert(shift_out == (16'hffff & (shift_in >> 2)));

        shift_by <= 3'b111;
        @(posedge ck);
        tb_assert(shift_out == (16'hffff & (shift_in >> 1)));

    end

    reg  en = 0;
    wire [1:0] src_addr;
    wire [23:0] in_data;
    wire done;

    reg [23:0] mic_0 = 0;
    reg [23:0] mic_1 = 0;
    reg [23:0] mic_2 = 0;
    reg [23:0] mic_3 = 0;

    function [23:0] get_mic(input [1:0] addr);
        begin
            case (addr)
                0   :   get_mic = mic_0;
                1   :   get_mic = mic_1;
                2   :   get_mic = mic_2;
                3   :   get_mic = mic_3;
            endcase
        end
    endfunction

    assign in_data = (src_addr == 0) ? mic_0 : 
                     ((src_addr == 1) ? mic_1 :  
                     ((src_addr == 2) ? mic_2 : 
                     mic_3));

    wire [4:0] level;
    wire [15:0] out;

    agc #(.IN_W(24), .CHANS(4))
    agc (
        .ck(ck),
        .en(en),
        .src_addr(src_addr),
        .in_data(in_data),
        .level(level),
        .out(out),
        .done(done)
    );

    task go;
        begin
            en <= 1;
            @(posedge ck);
            en <= 0;
            @(posedge ck);
        end
    endtask

    integer i;
 
    initial begin
        $display("test agc()");
        @(posedge ck);
        @(posedge ck);
        @(posedge ck);

        // Check it runs through the sequence
        mic_0 <= 24'h100000;
        mic_1 <= 24'h010000;
        mic_2 <= 24'h001000;
        mic_3 <= 24'h000100;
        go();
        wait(done);
        @(posedge ck);

        // Check that all channels are looked at
        mic_0 <= 24'h000001;
        mic_1 <= 24'h000000;
        mic_2 <= 24'h000000;
        mic_3 <= 24'h000000;
        @(posedge ck);
        go();
        wait(done);
        tb_assert(level == 22);

        mic_0 <= 24'h000000;
        mic_1 <= 24'h000001;
        mic_2 <= 24'h000000;
        mic_3 <= 24'h000000;
        @(posedge ck);
        go();
        wait(done);
        tb_assert(level == 22);

        mic_0 <= 24'h000000;
        mic_1 <= 24'h000000;
        mic_2 <= 24'h000001;
        mic_3 <= 24'h000000;
        @(posedge ck);
        go();
        wait(done);
        tb_assert(level == 22);

        mic_0 <= 24'h000000;
        mic_1 <= 24'h000000;
        mic_2 <= 24'h000000;
        mic_3 <= 24'h000001;
        @(posedge ck);
        go();
        wait(done);
        tb_assert(level == 22);

        // check each level
        mic_0 <= 24'h000000;
        mic_1 <= 24'h000000;
        mic_2 <= 24'h400000;
        mic_3 <= 24'h000000;
        for (i = 0; i < 24; i++) begin
            @(posedge ck);
            go();
            wait(done);
            @(posedge ck);
            tb_assert(level == i);
            mic_2 <= mic_2 >> 1;
        end

        // check each level for -ve levels
        mic_0 <= 24'h000000;
        mic_1 <= 24'h000000;
        mic_2 <= 24'hbfffff;
        mic_3 <= 24'h000000;
        for (i = 0; i < 22; i++) begin
            @(posedge ck);
            go();
            wait(done);
            @(posedge ck);
            tb_assert(level == i);
            mic_2 <= { 1'b1, mic_2[23:1] };
        end

        // Check mid-word transition, both signs
        mic_0 <= 24'h000000;
        mic_1 <= 24'hfff000;
        mic_2 <= 24'h000000;
        mic_3 <= 24'h000000;
        @(posedge ck);
        go();
        wait(done);
        tb_assert(level == 10);

        mic_0 <= 24'h000000;
        mic_1 <= 24'h000fff;
        mic_2 <= 24'h000000;
        mic_3 <= 24'h000000;
        @(posedge ck);
        go();
        wait(done);
        tb_assert(level == 11);

        @(posedge ck);
        @(posedge ck);

        $finish;
    end

    reg  gain_en = 0;
    reg  [15:0] gain_gain = 0;
    wire [1:0] gain_addr;
    wire signed [23:0] gain_in_data;
    wire signed [15:0] gain_out_data;
    wire [1:0] gain_out_addr;
    wire gain_out_we;
    wire gain_done;

    reg  signed [32:0] in_0 = 0;
    reg  signed [32:0] in_1 = 0;
    reg  signed [32:0] in_2 = 0;
    reg  signed [32:0] in_3 = 0;

    assign gain_in_data = (gain_addr == 0) ? in_0 : 
                         ((gain_addr == 1) ? in_1 :  
                         ((gain_addr == 2) ? in_2 : 
                         in_3));

    gain #(.GAIN_W(16), .IN_W(24), .OUT_W(16), .CHANS(4))
    gain (
        .ck(ck),
        .en(gain_en),
        .gain(gain_gain),
        .addr(gain_addr),
        .in_data(gain_in_data),
        .out_data(gain_out_data),
        .out_addr(gain_out_addr),
        .out_we(gain_out_we),
        .done(gain_done)
    );

    reg signed [15:0] out_0 = 16'hZ;
    reg signed [15:0] out_1 = 16'hZ;
    reg signed [15:0] out_2 = 16'hZ;
    reg signed [15:0] out_3 = 16'hZ;

    always @(posedge ck) begin
        if (gain_out_we) begin
            case (gain_out_addr)
                0   :   out_0 <= gain_out_data;
                1   :   out_1 <= gain_out_data;
                2   :   out_2 <= gain_out_data;
                3   :   out_3 <= gain_out_data;
            endcase
        end
    end

    task gain_run;
        begin
            gain_en <= 1;
            @(posedge ck);
            gain_en <= 0;
            @(posedge ck);
            wait(gain_done);
            @(posedge ck);
        end
    endtask

    function [15:0] twosc(input signed [15:0] a);

        begin
            return a[15] ? (1 + ~a) : a;
        end

    endfunction

    function automatic [32:0] mul16(input signed [15:0] a, signed [15:0] b);

        integer sign;
        integer twosc;
        integer out;
        integer m16;

        begin

            $display("a=%x b=%x", a, b);

            sign = a[15];
            twosc = 16'hffff & ((~a) + 1);

            out = b * (sign ? twosc : a);
            $display("o=%x", out);

            m16 = sign ? (1 + ~out) : out;
            $display("m16=%x", m16);
            mul16 = m16;

        end

    endfunction

    function automatic signed [15:0] calc(input [23:0] value, input [15:0] gain);

        integer mantissa;
        integer exp;
        integer shift;
        integer v;

        begin

            $display("v=%x g=%x", value, gain);

            mantissa = { 1'b1, gain[12:0], 2'b1 };
            exp = gain[15:13];
            shift = 7 - exp;
            v = 16'hffff & (value >>> shift);
            $display("e=%x m=%x", exp, mantissa);
            $display("v=%x s=%x", v, shift);

            calc = mul16(v, mantissa);
        end

    endfunction

    initial begin

        @(posedge ck);
        @(posedge ck);

        gain_gain <= 16'hffff;

        in_0 <= 24'h111111;
        in_1 <= 24'h222222;
        in_2 <= 24'h444444;
        in_3 <= 24'h123456;
        gain_run();

        $display("%x", calc(in_0, gain_gain));

        //tb_assert(out_0 == 16'h1110);
        //tb_assert(out_1 == 16'h2220);
        //tb_assert(out_2 == 16'h4441);
        //tb_assert(out_3 == 16'h888b);

        gain_gain <= 16'hffff;

        in_0 <= 24'h111111;
        in_1 <= 24'h222222;
        in_2 <= 24'h444444;
        in_3 <= 24'h888888;
        gain_run();

    end


endmodule



