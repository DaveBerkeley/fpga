
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
    input wire D0,
    output wire D1,
    input wire D2,
    output wire D3,
    output wire D4,
    output wire D5,
    output wire D6,
    output wire D7,
    input wire SW1
);

    wire ck;
    assign ck = CLK; // 12MHz clock

    //  Prescaler

    reg [20:0] prescale = 0;

    always @(posedge ck) begin
        prescale <= prescale + 1;
    end

    // Debounce clock

    wire debounce;
    assign debounce = & prescale[19:0];

    //  SCK/WS Output - may be looped back into input

    wire i2s_sck_gen, i2s_ws_gen;
    /* verilator lint_off UNUSED */
    wire [5:0] nowt_posn;
    wire nowt_en;
    /* verilator lint_on UNUSED */

    // I2S local generator : output SCK and WS signals.
    // These can be looped back into the SCK/WS inputs if the unit is a Primary.
    i2s_clock #(.DIVIDER(6)) i2sck(.ck(ck), .sck(i2s_sck_gen), .ws(i2s_ws_gen), .en(nowt_en), .frame_posn(nowt_posn));

    //  Test the I2S Secondary

    wire sck, ws;
    wire i2s_sck_in, i2s_ws_in, en;
    wire [5:0] frame_posn;
    i2s_secondary sec(.ck(ck), .en(en), .sck(i2s_sck_in), .ws(i2s_ws_in), .frame_posn(frame_posn));

    assign sck = i2s_sck_in;
    assign ws = i2s_ws_in;

    //  Different generation modes

    reg [1:0] state = 0;
    
    //  Generate sinewave

    reg [6:0] addr;

    reg signed [15:0] signal_0 = 0;
    reg signed [15:0] signal_1 = 0;
    reg signed [15:0] signal_2 = 0;
    reg signed [15:0] signal_3 = 0;

    reg [7:0] pulse_period = 0;
    reg [1:0] frame = 0;

    always @(posedge ck) begin
        if (en && (frame_posn == 0)) begin
            addr <= addr + 1;
            frame <= frame + 1;
            pulse_period <= pulse_period + 1;
            case (state)
                0 : begin
                    signal_0 <= sin(addr);
                    signal_1 <= sin(addr << 1);
                    signal_2 <= sin(addr << 2);
                    signal_3 <= sin(addr << 3);
                end
                1 : begin
                    signal_0 <= sin(addr << 2);
                    signal_1 <= sin(addr << 3);
                    signal_2 <= sin(addr << 4);
                    signal_3 <= sin(addr << 5);
                end
                2 : begin
                    signal_0 <= sin(addr << 3);
                    signal_1 <= sin(addr << 4);
                    signal_2 <= sin(addr << 5);
                    signal_3 <= sin(addr << 6);
                end
                3 : begin
                    // Unit impulse
                    if (pulse_period == 0) begin
                        signal_0 <= 16'h7ff0;
                        signal_1 <= 16'h8010;
                        signal_2 <= 16'h7ff0;
                        signal_3 <= 16'h8010;
                    end else begin
                        signal_0 <= 16'h0000;
                        signal_1 <= 16'h0000;
                        signal_2 <= 16'h0000;
                        signal_3 <= 16'h0000;
                    end
                end
            endcase
        end
    end

    wire d0, d1;
    i2s_tx tx_0(.ck(ck), .en(en), .frame_posn(frame_posn), .left(signal_0), .right(signal_1), .sd(d0));
    i2s_tx tx_1(.ck(ck), .en(en), .frame_posn(frame_posn), .left(signal_2), .right(signal_3), .sd(d1));

    //  User Switch

    reg sw1 = 0;

    always @(posedge ck) begin
        if (debounce) begin
            sw1 <= SW1;
            if (SW1 && !sw1) begin
                state <= state + 1;
            end
        end
    end

    //  LEDS
 
    reg [3:0] counter = 0;

    wire next;
    assign next = (counter == 0) ? 1 : 0;

    always @(posedge ck) begin
        if (prescale == 0)
            counter <= { counter[2:0], next };
    end

    assign LED0 = state == 0;
    assign LED1 = state == 1;
    assign LED2 = state == 2;
    assign LED3 = state == 3;
    assign LED4 = counter[0];
    assign LED5 = counter[1];
    assign LED6 = counter[2];
    assign LED7 = counter[3];

    // Sync Audio Input
    assign i2s_sck_in = D0;
    assign D1 = i2s_sck_gen;
    assign i2s_ws_in = D2;
    assign D3 = i2s_ws_gen;

    // Drive Audio Output
    assign D4 = sck;
    assign D5 = ws;
    assign D6 = d0;
    assign D7 = d1;

endmodule
