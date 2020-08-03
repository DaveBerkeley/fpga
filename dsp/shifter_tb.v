
`default_nettype none
`timescale 1ns / 100ps

module tb ();

    initial begin
        $dumpfile("dsp.vcd");
        $dumpvars(0, tb);
        #500000 $finish;
    end

    reg ck = 0;

    always #42 ck <= !ck;

    reg en = 0;
    reg [4:0] shift = 0;
    reg [39:0] in = 0;
    wire [15:0] out;

    shifter #(.SHIFT_W(5)) shifter (
        .ck(ck),
        .en(en),
        .shift(shift),
        .in(in),
        .out(out)
    );

    integer i;

    initial begin
        @(posedge ck);
        @(posedge ck);

        in <= 40'h00abcd1234;
        en <= 1;

        for (i = 0; i < 24; i = i + 1) begin

            shift <= i;
            @(posedge ck);
            @(posedge ck);
            tb_assert(out == ((in >> shift) & 16'hFFFF));
            
        end

    end

endmodule

