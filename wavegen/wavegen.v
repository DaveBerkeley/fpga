
`include "wave.v"

   /*
    *
    */

module multiplier(
    input wire ck,
    input  wire signed [15:0] a,
    input wire signed [15:0] b,
    output reg signed [31:0] out
);

    always @(negedge ck) begin
        out <= a * b;
    end

endmodule


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
    output wire D0,
    output wire D1,
    output wire D2,
    output wire D3,
    output wire D4,
    output wire D5
);

    wire i2s_ck, i2s_ws;
    /* verilator lint_off UNUSED */
    wire [5:0] frame_posn;
    wire [7:0] frame;
    /* verilator lint_on UNUSED */

    i2s_clock #(.DIVIDER(4)) i2sck(.ck(ck), .sck(i2s_ck), .ws(i2s_ws), .frame_posn(frame_posn), .frame(frame));

    assign D3 = i2s_ck;
    assign D4 = i2s_ws;

    reg [6:0] addr;

    //reg signed [15:0] gain = 0;

    //always @(negedge i2s_ws) begin
    //    gain <= gain + 1;
    //end

    reg signed [15:0] signal;

    //multiplier mul(.ck(i2s_ws), .a(gain), .b(signal), .out(audio));

    always @(negedge i2s_ws) begin
        addr <= addr + 1;
        signal <= sin(addr);
    end

    reg [63:0] shift;
    wire signed [31:0] audio;
    wire [1:0] extend;

    assign extend = {2{signal[15]}};
    assign audio = { extend, signal, 14'h0 };

    always @(negedge i2s_ck) begin
        if (frame_posn == 0)
            shift <= { audio, audio };
        else
            shift <= shift << 1;
    end

    assign D5 = shift[63];

    reg [7:0] tx_data = 8'h41;
    /* verilator lint_off UNUSED */
    wire tx_ready;
    /* verilator lint_on UNUSED */
    wire tx;
    wire baud;
    uart u(.ck(ck), .tx_data(tx_data), .ready(tx_ready), .tx(tx), .baud(baud));

    assign TX = tx;
    assign D0 = tx;
    assign D1 = baud;
    assign D2 = tx_ready;

    wire ck;
    assign ck = CLK;

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

endmodule
