
module top (input CLK, output P1A1, output P1A2, input P1A3);

reg [15:0] left;
reg [15:0] right;

I2S_IN i2s(CLK, P1A1, P1A2, P1A3, left, right);

endmodule

