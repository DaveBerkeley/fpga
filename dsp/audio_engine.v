
`default_nettype none

   /*
    *   Audio Perihperal
    */

module audio_engine (
    input wire ck,
    input wire wb_rst,
    input wire wb_dbus_cyc,
    output wire ack,
    input wire wb_dbus_we,
    /* verilator lint_off UNUSED */
    input wire [3:0] wb_dbus_sel,
    input wire [31:0] wb_dbus_adr,
    /* verilator lint_on UNUSED */
    input wire [31:0] wb_dbus_dat,
    output wire [31:0] rdt,

    output wire sck,    // I2S clock
    output wire ws,     // I2S word select
    output wire sd_out, // I2S data out
    input wire sd_in0,  // I2S data in
    input wire sd_in1,  // I2S data in
    input wire sd_in2,  // I2S data in
    input wire sd_in3,  // I2S data in
    output wire ready,
    output wire [7:0] test
);

    parameter                ADDR = 8'h60;

    localparam ADDR_COEF   = ADDR;
    localparam ADDR_RESULT = ADDR + 8'h01;
    localparam ADDR_STATUS = ADDR + 8'h02;
    localparam ADDR_RESET  = ADDR + 8'h03;
    localparam ADDR_INPUT  = ADDR + 8'h04;

    localparam CHANNELS = 8;
    localparam FRAMES = 256;
    localparam CODE = 256;
    localparam CHAN_W = $clog2(CHANNELS);
    localparam FRAME_W = $clog2(FRAMES);
    localparam CODE_W = $clog2(CODE);
    localparam AUDIO = CHANNELS * FRAMES;
    localparam AUDIO_W = $clog2(AUDIO);

    // Send an extended reset pulse to the audio engine

    reg [1:0] resetx = 0;
    reg reset_req = 0;

    always @(posedge ck) begin
        if (reset_req || frame_reset_req) begin
            resetx <= 0;
        end else begin
            if (resetx != 2'b10) begin
                resetx <= resetx + 1;
            end
        end
    end

    // TODO : reset is active low!!!!!
    wire reset;
    assign reset = !((!wb_rst) && (resetx == 2'b10));

    reg [(FRAME_W-1):0] frame_counter = 0;
    wire [(FRAME_W-1):0] frame;

    //  Control Register

    // bit-0 : set to allow writes to the audio input RAM
    // bits 1..6 optionally control the frame register
    localparam CONTROL_W = FRAME_W + 1;
    reg [(CONTROL_W-1):0] control_reg = 0;

    wire allow_audio_writes;
    assign allow_audio_writes = control_reg[0];

    assign frame = allow_audio_writes ? control_reg[(CONTROL_W-1):1] : frame_counter;

    //  I2S clock generation

    wire i2s_clock;

    // Divide the 32Mhz clock down to 2MHz
    // Gives 2e6/64 = 31250 Hz frame rate
    localparam I2S_DIVIDER = 16;
    localparam I2S_BIT_WIDTH = $clog2(I2S_DIVIDER);
    assign i2s_clock = ck;

    wire [5:0] frame_posn;
    wire i2s_en;
    i2s_clock #(.DIVIDER(I2S_DIVIDER)) 
    i2s_out(
        .ck(i2s_clock),
        .en(i2s_en),
        .sck(sck),
        .ws(ws),
        .frame_posn(frame_posn)
    );

    //  I2S Input

    reg writing = 0;
    reg frame_reset_req = 0;
    reg [(CHAN_W-1):0] chan_addr = 0;
    wire [(AUDIO_W-1):0] write_addr;
    wire write_en;
    wire [15:0] write_data;

    assign write_addr = { chan_addr, frame_counter };
    assign write_data = writing ? mic_source(chan_addr) : 0;
    assign write_en = writing;

    wire [15:0] mic_0;
    wire [15:0] mic_1;
    wire [15:0] mic_2;
    wire [15:0] mic_3;
    wire [15:0] mic_4;
    wire [15:0] mic_5;
    wire [15:0] mic_6;
    wire [15:0] mic_7;

    i2s_rx #(.WIDTH(I2S_BIT_WIDTH)) 
        rx_0(.ck(ck), .en(i2s_en), .frame_posn(frame_posn), .sd(sd_in0), .left(mic_0), .right(mic_1));
    i2s_rx #(.WIDTH(I2S_BIT_WIDTH)) 
        rx_1(.ck(ck), .en(i2s_en), .frame_posn(frame_posn), .sd(sd_in1), .left(mic_2), .right(mic_3));
    i2s_rx #(.WIDTH(I2S_BIT_WIDTH)) 
        rx_2(.ck(ck), .en(i2s_en), .frame_posn(frame_posn), .sd(sd_in2), .left(mic_4), .right(mic_5));
    i2s_rx #(.WIDTH(I2S_BIT_WIDTH)) 
        rx_3(.ck(ck), .en(i2s_en), .frame_posn(frame_posn), .sd(sd_in3), .left(mic_6), .right(mic_7));

    //  I2S Output

    reg [15:0] left = 0;
    reg [15:0] right = 0;

    i2s_tx tx(
        .ck(ck),
        .en(i2s_en),
        .frame_posn(frame_posn),
        .left(left),
        .right(right),
        .sd(sd_out)
    );

    //  Write Input data to the Audio RAM

    function [15:0] mic_source(input [(CHAN_W-1):0] chan);
 
        begin
            case (chan)
                0   :   mic_source = mic_0;
                1   :   mic_source = mic_1;
                2   :   mic_source = mic_2;
                3   :   mic_source = mic_3;
                4   :   mic_source = mic_4;
                5   :   mic_source = mic_5;
                6   :   mic_source = mic_6;
                7   :   mic_source = mic_7;
            endcase
        end

    endfunction

    always @(posedge ck) begin
        // Check that the host processor isn't in write mode
        if (!allow_audio_writes) begin

            if (ws && (frame_posn == 0)) begin
                chan_addr <= 0;
                writing <= 1;
                frame_counter <= frame_counter - 1;
            end else begin
                chan_addr <= chan_addr + 1;
            end

            /* verilator lint_off WIDTH */
            if (writing && (chan_addr == (CHANNELS-1))) begin
                writing <= 0;
                frame_reset_req <= 1;
            end
            /* verilator lint_on WIDTH */

            if (frame_reset_req)
                frame_reset_req <= 0;

        end
    end

    //  Drive the engine

    wire [7:0] cs_adr;
    assign cs_adr = wb_dbus_adr[31:24];

    wire coef_ack, coef_cyc;

    chip_select #(.ADDR(ADDR_COEF)) 
    cs_coef(
        .wb_ck(ck),
        .addr(cs_adr),
        .wb_cyc(wb_dbus_cyc),
        .wb_rst(wb_rst),
        .ack(coef_ack),
        .cyc(coef_cyc)
    );

    // Coefficient / Program DP RAM
    // This is written to by the host, read by the engine.
    wire coef_we;
    wire [(CODE_W-1):0] coef_waddr;
    wire [31:0] coef_rdata;
    wire [(CODE_W-1):0] coef_raddr;

    assign coef_we = wb_dbus_we & coef_cyc;
    assign coef_waddr = wb_dbus_adr[CODE_W+2-1:2];

    dpram #(.BITS(32), .SIZE(CODE))
        coef (.ck(ck),
            .we(coef_we), .waddr(coef_waddr), .wdata(wb_dbus_dat),
            .re(1'h1), .raddr(coef_raddr), .rdata(coef_rdata));

    // Audio Input DP RAM
    // Audio Input data is written into this RAM
    // and read out by the audio engine.

    wire input_ack, input_cyc;

    chip_select #(.ADDR(ADDR_INPUT)) 
    cs_input(
        .wb_ck(ck),
        .addr(cs_adr),
        .wb_cyc(wb_dbus_cyc),
        .wb_rst(wb_rst),
        .ack(input_ack),
        .cyc(input_cyc)
    );

    wire [15:0] audio_wdata;
    wire [(AUDIO_W-1):0] audio_waddr;
    wire [15:0] audio_rdata;
    wire [(AUDIO_W-1):0] audio_raddr;

    wire input_we;
    assign input_we = wb_dbus_we & input_cyc;

    wire audio_we;
    // allow audio writes from I2S input or from host processor
    assign audio_we    = allow_audio_writes ? input_we                      : write_en;
    assign audio_waddr = allow_audio_writes ? wb_dbus_adr[(AUDIO_W+2-1):2]  : write_addr;
    assign audio_wdata = allow_audio_writes ? wb_dbus_dat[15:0]             : write_data;

    dpram #(.BITS(16), .SIZE(AUDIO)) 
    audio_in (.ck(ck),
        .we(audio_we), 
        .waddr(audio_waddr), 
        .wdata(audio_wdata),
        .re(1'h1), 
        .raddr(audio_raddr), 
        .rdata(audio_rdata)
    );

    // Sequencer : main DSP Engine

    /* verilator lint_off UNUSED */
    wire [3:0] out_wr_addr;
    /* verilator lint_on UNUSED */
    wire [15:0] out_audio;
    wire out_we;
    wire error;
    wire done;
    wire [31:0] capture;

    sequencer #(.CHAN_W(CHAN_W), .FRAME_W(FRAME_W), .AUDIO_W(AUDIO_W))
    seq (
        .ck(ck),
        .rst(reset),
        .frame(frame),
        .coef_addr(coef_raddr),
        .coef_data(coef_rdata), 
        .audio_raddr(audio_raddr),
        .audio_in(audio_rdata),
        .out_addr(out_wr_addr),
        .out_audio(out_audio),
        .out_we(out_we),
        .done(done),
        .error(error), 
        .capture_out(capture)
    );

    //  Results RAM
    //  currently just using a pair of registers, left & right

    always @(posedge ck) begin
        if (out_we) begin
            if (out_wr_addr[0] == 0)
                left <= out_audio;
            else
                right <= out_audio;
        end
    end

    wire [15:0] result_rdata;
    wire [0:0] result_raddr;

    assign result_raddr = wb_dbus_adr[2];
    assign result_rdata = result_raddr ? right : left;

    // Interface the peripheral to the Risc-V bus

    //  Request DSP reset (begin processing from start)

    wire reset_ack, reset_cyc;

    chip_select #(.ADDR(ADDR_RESET)) 
    cs_reset(
        .wb_ck(ck),
        .addr(cs_adr),
        .wb_cyc(wb_dbus_cyc),
        .wb_rst(wb_rst),
        .ack(reset_ack),
        .cyc(reset_cyc)
    );

    // A write to the reset register causes a reset to be issued to the engine
    always @(posedge ck) begin
        if (reset_cyc & wb_dbus_we) begin
            reset_req <= 1;
        end
        if (reset_req) begin
            reset_req <= 0;
        end
    end

    wire result_ack, result_cyc;

    chip_select #(.ADDR(ADDR_RESULT)) 
    cs_result(
        .wb_ck(ck),
        .addr(cs_adr),
        .wb_cyc(wb_dbus_cyc),
        .wb_rst(wb_rst),
        .ack(result_ack),
        .cyc(result_cyc)
    );

    wire [31:0] result_rdt;

    assign result_rdt = (result_cyc & !wb_dbus_we) ? { 16'h0, result_rdata } : 0;

    //  Read / Write the control reg

    wire status_ack, status_cyc;

    chip_select #(.ADDR(ADDR_STATUS)) 
    cs_status(
        .wb_ck(ck),
        .addr(cs_adr),
        .wb_cyc(wb_dbus_cyc),
        .wb_rst(wb_rst),
        .ack(status_ack),
        .cyc(status_cyc)
    );
    
    always @(posedge ck) begin
        if (status_cyc & wb_dbus_we) begin
            control_reg <= wb_dbus_dat[(CONTROL_W-1):0];
        end
    end

    wire [31:0] control_rdt;
    wire [31:0] status_rdt;

    assign control_rdt = { 30'h0, error, done };
    assign status_rdt = (status_cyc & !wb_dbus_we) ? (wb_dbus_adr[2] ? capture : control_rdt) : 0;

    //  OR the ACK and RST signals together

    assign ack = result_ack | status_ack | coef_ack | input_ack | reset_ack;
    assign rdt = result_rdt | status_rdt;
    assign ready = done;

    //  Test output

    assign test[0] = done;
    assign test[1] = reset;
    assign test[2] = input_ack;
    assign test[3] = reset_ack;
    assign test[4] = result_ack;
    assign test[5] = 0;
    assign test[6] = 0;
    assign test[7] = 0;

endmodule

//  FIN
