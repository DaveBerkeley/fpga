
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

    localparam S_MAX = (1 << WIDTH) - 1;

    initial frame_posn = 0;
    initial en = 0;

    // need to align the input signals to the ck
    // as they may be external async signals

    reg ws0, sck0;

    always @(posedge ck) begin
        sck0 <= sck;
        ws0  <= ws;
    end

    // find the start of the frame using delayed ws
    reg prev_ws = 0;
    wire start_frame;

    // find a clock enable using delayed sck
    reg prev_sck = 0;
    wire ck_in;

    always @(posedge ck) begin
        prev_ws <= ws0;
        prev_sck <= sck0;
    end    

    // These signals are both delayed by one clock
    assign start_frame = prev_ws & !ws0;
    assign ck_in = prev_sck && !sck0;

    // count the clocks in an sck period to see how long it is
    reg [(WIDTH-1):0] prescale = 0;
    reg [(WIDTH-1):0] match = 0;

    always @(posedge ck) begin

        if (ck_in) begin 
            prescale <= 0;
            match <= prescale - 3;
        end else begin
            if (prescale != S_MAX) begin
                prescale <= prescale + 1;
            end
        end

    end

    // when prescale == match, we are 2 clocks before the ck_in signal
    // which means we lead the sck by one clock period.
    wire start_sck;
    assign start_sck = prescale == match;

    always @(posedge ck) begin

        en <= start_sck;

        if (start_sck) begin
            frame_posn <= frame_posn + 1;
        end

        if (start_frame) begin
            frame_posn <= 0;
        end

    end

endmodule

   /*
    * Detect External I2S sync
    */

module i2s_detect
#(parameter WIDTH=5)
(
    input wire ck,
    input wire ext_en,
    input wire gen_en,
    output wire external
);

    localparam S_MAX = (1 << WIDTH) - 1;

    reg [WIDTH-1:0] counter = S_MAX;

    always @(posedge ck) begin

        if (ext_en) begin
            // Any signal on EXT indicates external sync
            counter <= 0;
        end else begin
            if (gen_en && (counter < S_MAX)) begin
                counter <= counter + 1;
            end
        end

    end

    assign external = counter != S_MAX;

endmodule

   /*
    *   Sync to EXT I2S signals, or generate locally.
    */

module i2s_dual
#(parameter DIVIDER=16, WIDTH=$clog2(DIVIDER)+1)
(
    input wire ck,
    input wire rst,
    input wire ext_sck,
    input wire ext_ws,
    output wire sck,
    output wire ws,
    output wire en,
    output wire [5:0] frame_posn
);

    // Local I2S clock generation
    wire local_en;
    wire local_sck;
    wire local_ws;
    wire [5:0] local_frame_posn;

    i2s_clock #(.DIVIDER(DIVIDER))
    i2s_clock(
        .ck(ck),
        .rst(rst),
        .en(local_en),
        .sck(local_sck),
        .ws(local_ws),
        .frame_posn(local_frame_posn)
    );

    // Attempt to sync to external I2S
    wire ext_en;
    wire [5:0] ext_frame_posn;

    i2s_secondary #(.WIDTH(WIDTH))
    i2s_secondary(
        .ck(ck),
        .sck(ext_sck),
        .ws(ext_ws),
        .en(ext_en),
        .frame_posn(ext_frame_posn)
    );

    // Detect EXT sync
    wire external;

    i2s_detect #(.WIDTH(WIDTH))
    i2s_detect(
        .ck(ck),
        .ext_en(ext_en),
        .gen_en(local_en),
        .external(external)
    );

    // Select external or local outputs
    assign sck          = external ? ext_sck        : local_sck;
    assign ws           = external ? ext_ws         : local_ws;
    assign en           = external ? ext_en         : local_en;
    assign frame_posn   = external ? ext_frame_posn : local_frame_posn;

endmodule

//  FIN
