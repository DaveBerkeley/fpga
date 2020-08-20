
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

    reg [23:0] mic_0 = 24'hZ;
    reg [23:0] mic_1 = 24'hZ;
    reg [23:0] mic_2 = 24'hZ;
    reg [23:0] mic_3 = 24'hZ;

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

    assign in_data = get_mic(src_addr);

    agc #(.IN_W(24), .CHANS(4))
    agc (
        .ck(ck),
        .en(en),
        .src_addr(src_addr),
        .in_data(in_data),
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
 
    initial begin
        $display("test agc()");
        @(posedge ck);
        @(posedge ck);

        mic_0 <= 24'h000456;
        mic_1 <= 24'h010123;
        mic_2 <= 24'hffe000;
        mic_3 <= 24'hfbcdef;
        go();
        wait(done);

        @(posedge ck);


        $finish;
    end

endmodule



