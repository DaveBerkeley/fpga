
module top(input wire CLK, output wire TX);

    wire ck;

    wire led;
    assign TX = led;

    pll clock(.clock_in(CLK), .clock_out(ck));

    parameter memfile = "zephyr_hello.hex";

    service #(.memfile(memfile)) cpu(.i_clk(ck), .q(led));

endmodule
