
`default_nettype none

module top (
    input wire clk,
    input wire btn,
    //output wire reset,
    output wire r,
    output wire g,
    output wire b,
    output wire p0,
    output wire p1,
    output wire p5,
    output wire p6,
    output wire p9,
    output wire p10,
    output wire p11,
    output wire p12,
    output wire p13
);

    reg [28:0] divider = 0;

    always @(posedge clk) begin
        divider <= divider + 1;
    end

   /*
    *
    */

    //  DSP interface
    /* verilator lint_off UNUSED */
    wire ext_ck;

    assign ext_ck = clk;

    wire tx; 

    // XIP Flash
    wire spi_sck;
    wire spi_cs;
    wire spi_mosi;
    reg spi_miso = 0;

    wire [7:0] test;

    // sk9822 drive
    wire led_ck;
    wire led_data;

    // I2S
    wire sck;
    wire ws;
    // Mic in
    reg sd_in0 = 0;
    reg sd_in1 = 0;
    reg sd_in2 = 0;
    reg sd_in3 = 0;
 
    // I2S Output
    wire o_sck;
    wire o_ws;
    wire o_sd;

    // External I2S sync input, SD output
    reg ext_sck = 0;
    reg ext_ws = 0;
    wire ext_sd;
    /* verilator lint_on UNUSED */

    dsp dsp (
        .ext_ck(ext_ck),
        .tx(tx),
        .spi_sck(spi_sck),
        .spi_cs(spi_cs),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .test(test),
        .led_ck(led_ck),
        .led_data(led_data),
        .sck(sck),
        .ws(ws),
        .sd_in0(sd_in0),
        .sd_in1(sd_in1),
        .sd_in2(sd_in2),
        .sd_in3(sd_in3),
        .o_sck(o_sck),
        .o_ws(o_ws),
        .o_sd(o_sd),
        .ext_sck(ext_sck),
        .ext_ws(ext_ws),
        .ext_sd(ext_sd)
    );

    assign r = btn; // divider[24];
    assign g = divider[25];
    assign b = divider[26];

    assign p0  = led_ck;
    assign p1  = led_data;
    assign p5  = spi_sck;
    assign p6  = spi_cs;
    assign p9  = spi_mosi;

    assign p10 = test[0];
    assign p11 = test[1];
    assign p12 = test[2];
    assign p13 = tx;

endmodule

   /*
    *   Dummy modules
    */

module pll(
    input wire clock_in,
    output wire clock_out,
    output wire locked
);

    assign clock_out = clock_in;
    assign locked = 1;

endmodule

//  FIN
