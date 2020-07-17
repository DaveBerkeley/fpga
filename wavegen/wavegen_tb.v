
`default_nettype none
`timescale 1ns / 100ps

   /*
    *
    */

module tb();

    initial begin
        $dumpfile("wavegen.vcd");
        $dumpvars(0, tb);
        #500000 $finish;
    end

    reg ck = 0;

    always #42 ck <= !ck;

    wire d0, d1, d2, d3;

    top top(.CLK(ck), .D0(d0), .D1(d1), .D2(d2), .D3(d3));

    // feeed the generated signal back
    assign d0 = d1;
    assign d2 = d3;

endmodule

