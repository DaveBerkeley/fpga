
`include "wave.v"

   /*
    *
    */

module top (
    input wire CLK, 
    output wire LED0,
    output wire LED1,
    output wire LED2,
    output wire LED3,
    output wire LED4,
    output wire LED5,
    output wire LED6,
    output wire LED7,
    output wire TX,
    input wire D0,
    output wire D1,
    input wire D2,
    output wire D3,
    output wire D4,
    output wire D5,
    output wire D6
);

    wire ck_12mhz;
    wire ck;

    assign ck_12mhz = CLK;

    // 22.58 MHz PLL clock derived from ck_12mhz clock input
    /* verilator lint_off PINCONNECTEMPTY */
    pll clock(.clock_in(ck_12mhz), .clock_out(ck), .locked());
    /* verilator lint_on PINCONNECTEMPTY */

    // 44.1kHz audio * 64-bits per frame = 22.58/8 MHz

    wire i2s_sck, i2s_ws;
    /* verilator lint_off UNUSED */
    wire [5:0] posn;
    /* verilator lint_on UNUSED */

    i2s_clock #(.DIVIDER(16)) i2sck(.ck(ck), .sck(i2s_sck), .ws(i2s_ws), .frame_posn(posn));

    //  Test the I2S Secondary

    wire i2s_sck_in, i2s_ws_in;
    wire [5:0] frame_posn;
    i2s_secondary sec(.sck(i2s_sck_in), .ws(i2s_ws_in), .frame_posn(frame_posn));

    //  Generate sinewave

    reg [6:0] addr;

    reg signed [15:0] signal_l = 0;
    reg signed [15:0] signal_r = 0;

    always @(negedge i2s_ws) begin
        addr <= addr + 1;
        signal_l <= sin(addr);
        signal_r <= sin(addr << 1);
    end

    wire d0;
    i2s_tx tx_0(.sck(i2s_sck_in), .frame_posn(frame_posn), .left(signal_l), .right(signal_r), .sd(d0));

    //  UART

    reg [7:0] tx_data = 8'h41;
    /* verilator lint_off UNUSED */
    wire tx_ready;
    wire baud;
    /* verilator lint_on UNUSED */
    wire tx;
    uart u(.ck(ck_12mhz), .tx_data(tx_data), .ready(tx_ready), .tx(tx), .baud(baud));

    reg [20:0] prescale = 0;

    always @(negedge ck) begin
        prescale <= prescale + 1;
    end
 
    reg [7:0] counter = 0;

    wire next;
    assign next = (counter == 0) ? 1 : 0;

    always @(negedge ck) begin
        if (prescale == 0)
            counter <= { counter[6:0], next };
    end

    assign LED0 = counter[0];
    assign LED1 = counter[1];
    assign LED2 = counter[2];
    assign LED3 = counter[3];
    assign LED4 = counter[4];
    assign LED5 = counter[5];
    assign LED6 = counter[6];
    assign LED7 = counter[7];

    assign TX = tx;

    // Sync Audio Input
    assign i2s_sck_in = D0;
    assign D1 = i2s_sck;
    assign i2s_ws_in = D2;
    assign D3 = i2s_ws;

    // Drive Audio Output
    assign D4 = i2s_sck_in;
    assign D5 = i2s_ws_in;
    assign D6 = d0;

endmodule
