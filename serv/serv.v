
module top(
    input wire CLK, 
    output wire TX, 
    output wire LED1,
    output wire P1A1,
    output wire P1A2,
    output wire P1A3,
    output wire P1A4,
    output wire P1B1,
    output wire P1B2,
    output wire P1B3,
    output wire P1B4
);

    wire [7:0] test;

    assign P1A1 = test[0];
    assign P1A2 = test[1];
    assign P1A3 = test[2];
    assign P1A4 = test[3];
    assign P1B1 = test[4];
    assign P1B2 = test[5];
    assign P1B3 = test[6];
    assign P1B4 = test[7];

    soc soc(
        .clk(CLK),
        .test(test),
        .led(LED1),
        .tx(TX)
    );

endmodule
