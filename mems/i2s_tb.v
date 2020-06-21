
`default_nettype none
`timescale 1ns / 100ps

module i2s_tb();

wire sck;
wire ws;
reg sd;
wire [15:0] do;

I2S_IN i2s(clock, sck, ws, sd, do, do);

// Signals
reg clock = 1;

initial begin
    $dumpfile("i2s.vcd");
    $dumpvars(0, i2s_tb);
    sd <= 0;
    #500000 $finish;
end

// Clock ~= 12Mhz
always #84 clock <= !clock;

always @(negedge sck) begin
    # 1;
    sd <= !sd;
end

endmodule

