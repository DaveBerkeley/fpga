
   /*
    *   Generate frame_posn bit index from I2S sck and ws signals
    */

module i2s_secondary
    #(parameter WIDTH=5)
    (input wire ck,
    input wire sck,
    input wire ws,
    output reg en,
    output reg [5:0] frame_posn
);

    initial frame_posn = 0;
    initial en = 0;

    // find the start of the frame using delayed ws
    reg prev_ws = 0;
    wire start_frame;

    // find a clock enable using delayed sck
    reg prev_sck = 0;
    wire ck_in;

    always @(posedge ck) begin
        prev_ws <= ws;
        prev_sck = sck;
    end    

    // These signals are both delayed by one clock
    assign start_frame = prev_ws & !ws;
    assign ck_in = prev_sck && !sck;

    // count the clocks in an sck period to see how long it is
    reg [(WIDTH-1):0] prescale = 0;
    reg [(WIDTH-1):0] match = 0;

    always @(posedge ck) begin

        if (ck_in) begin 
            prescale <= 0;
            match <= prescale - 2;
        end else begin
            prescale <= prescale + 1;
        end

    end

    // when prescale == match, we are 2 clocks before the ck_in signal
    // which means we lead the sck by one clock period.
    wire start_sck;
    assign start_sck = prescale == match;
    
    always @(posedge ck) begin

        en <= start_sck;

        if (start_sck)
            frame_posn <= frame_posn + 1;

        if (start_frame)
            frame_posn <= 0;

    end

endmodule


