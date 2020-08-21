
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

    agc #(.IN_W(24), .CHANS(4))
    agc (
        .ck(ck),
        .en(en),
        .src_addr(src_addr),
        .in_data(in_data),
        .level(level),
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
        mic_0 <= -1;
        mic_1 <= -16;
        mic_2 <= -256;
        mic_3 <= -1024;
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

endmodule



