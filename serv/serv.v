
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

    // PLL
    wire pll_ck;
    /* verilator lint_off UNUSED */
    wire locked;
    /* verilator lint_on UNUSED */
    pll clock(.clock_in(CLK), .clock_out(pll_ck), .locked(locked));

    reg [3:0] prescale = 0;

    always @(posedge pll_ck) begin
        prescale <= prescale + 1;
    end

    wire ck;
    assign ck = prescale[3];

    // Reset generator
    reg [4:0] rst_reg = 5'b11111;
    wire reset_req;

    always @(posedge ck) begin
        if (reset_req)
            rst_reg <= 5'b11111;
        else
            rst_reg <= {1'b0, rst_reg[4:1]};
    end

    wire rst;
    assign rst = rst_reg[0];

    //  Continually Reset the cpu

    reg [11:0] reseter = 0;

    always @(posedge ck) begin
        reseter <= reseter + 1;
    end

    assign reset_req = reseter == 0;

    soc soc(
        .clk(ck),
        .rst(rst),
        .test(test),
        .led(LED1),
        .tx(TX)
    );

endmodule
