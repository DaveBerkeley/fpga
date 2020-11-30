

`default_nettype none

   /*
    *
    */

module top (
    input wire CLK, 
    output wire TX, 

    // XIP Flash
    output wire FLASH_SCK,
    output wire FLASH_SSB,
    output wire FLASH_IO0,
    input  wire FLASH_IO1,
    output wire FLASH_IO2,
    output wire FLASH_IO3,

    output wire P2_1,
    output wire P2_2,
    output wire P2_3,
    output wire P2_4,
    output wire P2_7,
    output wire P2_8,
    output wire P2_9

    // Test pins
    //input wire P1A1,
    //input wire P1A2,
    //output wire P1A3,
    //output wire P1A4,

    // I2S Input
    //output wire P1A7,
    //output wire P1A8,
    //input wire P1A9,
    //input wire P1A10,
    
    // I2S Output
    //output wire P1B1,
    //output wire P1B2,
    //output wire P1B3,
    //output wire P1B4,

    //input wire P1B7,
    //input wire P1B8,
    //output wire P1B9,
    //output wire P1B10
);

    /* verilator lint_off UNUSED */
    wire [7:0] test_out;
    /* verilator lint_on UNUSED */

    assign P2_1 = test_out[0];
    assign P2_2 = test_out[1];
    assign P2_3 = test_out[2];
    assign P2_4 = test_out[3];
    assign P2_7 = test_out[4];
    assign P2_8 = test_out[5];
    assign P2_9 = test_out[6];

    assign FLASH_IO2 = 1;
    assign FLASH_IO3 = 1;

    //assign P1B4 = 0;

    dsp dsp(
        .ext_ck(CLK),

        .tx(TX),

        .spi_sck(FLASH_SCK),
        .spi_cs(FLASH_SSB),
        .spi_mosi(FLASH_IO0),
        .spi_miso(FLASH_IO1),

        // Test pins
        .test(test_out)
    );

endmodule

