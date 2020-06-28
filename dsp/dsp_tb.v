
module tb ();

initial begin
    $dumpfile("dsp.vcd");
    $dumpvars(0, tb);
    #5000000 $finish;
end

reg ck = 0;

always #42 ck <= !ck;

wire lck;
wire ld;

top top_(.CLK(ck), .P1A1(lck), .P1A2(ld));

endmodule

