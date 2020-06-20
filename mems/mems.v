
module top (output P1A1, output P1A2, input P1A3);

I2S_IN i2s(CLK, P1A1, P1A2, P1A3);

mems_tb tb(CLK, P1A1, P1A2);

endmodule

