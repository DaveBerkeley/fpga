
   /*
    *   Audio Perihperal
    */

module audio_engine (
    input wire ck,
    input wire rst,
    input wire iomem_valid,
    output wire iomem_ready,
    input wire [3:0] iomem_wstrb,
    /* verilator lint_off UNUSED */
    input wire [31:0] iomem_addr,
    /* verilator lint_on UNUSED */
    input wire [31:0] iomem_wdata,
    output wire [31:0] iomem_rdata,
    output wire sck, // I2S clock
    output wire ws,  // I2S word select
    output wire sd_out,  // I2S data out
    output wire sd_in0,  // I2S data in
    output wire sd_in1,  // I2S data in
    output wire sd_in2,  // I2S data in
    output wire sd_in3,  // I2S data in
    output wire [7:0] test
);

    parameter                ADDR = 16'h6000;

    localparam ADDR_COEF   = ADDR;
    localparam ADDR_RESULT = ADDR + 16'h0100;
    localparam ADDR_STATUS = ADDR + 16'h0200;
    localparam ADDR_RESET  = ADDR + 16'h0300;
    localparam ADDR_INPUT  = ADDR + 16'h0400;

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

    always @(posedge ck) begin
        if (reset_req || frame_reset_req)
            resetx <= 0;
        else 
           if (resetx != 2'b10)
                resetx <= resetx + 1;
    end

    wire reset;
    assign reset = rst && (resetx == 2'b10);

    wire done;
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

//`ifdef SIMULATION
    // Divide the 12Mhz clock down to 2MHz
    localparam I2S_DIVIDER = 6;
    assign i2s_clock = ck;
//`else
//    // 45.16 MHz PLL clock derived from ck_12mhz clock input
//    /* verilator lint_off PINCONNECTEMPTY */
//    pll clock(.clock_in(ck), .clock_out(i2s_clock), .locked());
//    /* verilator lint_on PINCONNECTEMPTY */
//    localparam I2S_DIVIDER = 16;
//`endif

    wire [5:0] frame_posn;
    wire i2s_en;
    i2s_clock #(.DIVIDER(I2S_DIVIDER)) i2s_out(.ck(i2s_clock), .i2s_en(i2s_en),
            .sck(sck), .ws(ws), .frame_posn(frame_posn));

    //  I2S Output

    reg [15:0] left = 0;
    reg [15:0] right = 0;

    i2s_tx tx(.ck(ck), .en(i2s_en), .frame_posn(frame_posn), .left(left), .right(right), .sd(sd_out));

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
    //wire [15:0] mic_2;
    //wire [15:0] mic_3;
    //wire [15:0] mic_4;
    //wire [15:0] mic_5;
    //wire [15:0] mic_6;
    //wire [15:0] mic_7;

    i2s_rx rx_0(.ck(ck), .en(i2s_en), .frame_posn(frame_posn), .sd(sd_in0), .left(mic_0), .right(mic_1));
    //i2s_rx rx_1(.sck(sck), .frame_posn(frame_posn), .sd(sd_in1), .left(mic_2), .right(mic_3));
    //i2s_rx rx_2(.sck(sck), .frame_posn(frame_posn), .sd(sd_in2), .left(mic_4), .right(mic_5));
    //i2s_rx rx_3(.sck(sck), .frame_posn(frame_posn), .sd(sd_in3), .left(mic_6), .right(mic_7));

    //  Write Input data to the Audio RAM

    function [15:0] mic_source(input [(CHAN_W-1):0] chan);
 
        begin
            case (chan)
                0   :   mic_source = mic_0;
                1   :   mic_source = mic_1;
                //2   :   mic_source = mic_2;
                //3   :   mic_source = mic_3;
                //4   :   mic_source = mic_4;
                //5   :   mic_source = mic_5;
                //6   :   mic_source = mic_6;
                //7   :   mic_source = mic_7;
                default : mic_source = 16'h7fff;
            endcase
        end

    endfunction

    always @(posedge ck) begin
        // Check that the host processor isn't in write mode
        if (!allow_audio_writes) begin

            if (ws && (frame_posn == 0)) begin
                chan_addr <= 0;
                writing <= 1;
                frame_counter <= frame_counter + 1;
            end else begin
                chan_addr <= chan_addr + 1;
            end

            if (writing && (chan_addr == (CHANNELS-1))) begin
                writing <= 0;
                frame_reset_req <= 1;
            end

            if (frame_reset_req)
                frame_reset_req <= 0;

        end
    end

    assign test[0] = frame[0];

    //  Drive the engine

    // Coefficient / Program DP RAM
    // This is written to by the host, read by the engine.
    wire coef_we;
    wire [(CODE_W-1):0] coef_waddr;
    wire [31:0] coef_rdata;
    wire [(CODE_W-1):0] coef_raddr;

    dpram #(.BITS(32), .SIZE(CODE))
        coef (.ck(ck),
            .we(coef_we), .waddr(coef_waddr), .wdata(iomem_wdata),
            .re(1'h1), .raddr(coef_raddr), .rdata(coef_rdata));

    assign coef_waddr = iomem_addr[(2+CODE_W-1):2];

    // Audio Input DP RAM
    // Audio Input data is written into this RAM
    // and read out by the audio engine.

    wire audio_we;
    wire [15:0] audio_wdata;
    wire [(AUDIO_W-1):0] audio_waddr;
    wire [15:0] audio_rdata;
    wire [(AUDIO_W-1):0] audio_raddr;

    dpram #(.BITS(16), .SIZE(AUDIO)) 
        audio_in (.ck(ck),
            .we(audio_we), .waddr(audio_waddr), .wdata(audio_wdata),
            .re(1'h1), .raddr(audio_raddr), .rdata(audio_rdata));

    wire input_we;
    // allow audio writes from I2S input or from host processor
    assign audio_we    = allow_audio_writes ? input_we                      : write_en;
    assign audio_waddr = allow_audio_writes ? iomem_addr[(AUDIO_W+2-1):2]   : write_addr;
    assign audio_wdata = allow_audio_writes ? iomem_wdata[15:0]             : write_data;

    // Sequencer

    wire [3:0] out_wr_addr;
    wire [15:0] out_audio;
    wire out_we;
    wire error;

    wire [31:0] capture;

    sequencer #(.CHAN_W(CHAN_W), .FRAME_W(FRAME_W), .AUDIO_W(AUDIO_W)) seq (
            .ck(ck), .rst(reset), .frame(frame),
            .coef_addr(coef_raddr), .coef_data(coef_rdata), 
            .audio_raddr(audio_raddr), .audio_in(audio_rdata),
            .out_addr(out_wr_addr), .out_audio(out_audio), .out_we(out_we),
            .done(done), .error(error), 
            .capture_out(capture));

    //  Results RAM

    always @(posedge ck) begin
        if (out_we) begin
            if (out_wr_addr[0] == 0)
                left <= out_audio;
            else
                right <= out_audio;
        end
    end

    wire result_re;
    wire [15:0] result_rdata;
    wire [0:0] result_raddr;

    assign result_raddr = iomem_addr[2];
    assign result_rdata = result_raddr ? right : left;

    // Interface the peripheral to the Risc-V bus

    wire reset_en;
    wire coef_ready, reset_ready, input_ready, result_ready;

    /* verilator lint_off UNUSED */
    wire nowt_1, nowt_2, nowt_3, nowt_4;
    /* verilator lint_on UNUSED */

    iomem #(.ADDR(ADDR_COEF)) coef_io (.ck(ck),
                            .valid(iomem_valid), .wstrb(iomem_wstrb), .addr(iomem_addr),
                            .ready(coef_ready), .we(coef_we), .re(nowt_1));

    reg reset_req = 0;

    always @(posedge ck) begin
        reset_req <= reset_en;
    end

    iomem #(.ADDR(ADDR_RESET)) reset_io (.ck(ck),
                            .valid(iomem_valid), .wstrb(iomem_wstrb), .addr(iomem_addr),
                            .ready(reset_ready), .we(reset_en), .re(nowt_2));

    iomem #(.ADDR(ADDR_INPUT)) input_io (.ck(ck),
                            .valid(iomem_valid), .wstrb(iomem_wstrb), .addr(iomem_addr),
                            .ready(input_ready), .we(input_we), .re(nowt_3));

    reg [31:0] rd_result = 0;

    always @(posedge ck) begin
        if (result_re)
            rd_result <= { 16'h0, result_rdata };
        else
            rd_result <= 0;
    end

    iomem #(.ADDR(ADDR_RESULT)) result_io (.ck(ck),
                            .valid(iomem_valid), .wstrb(iomem_wstrb), .addr(iomem_addr),
                            .ready(result_ready), .we(nowt_4), .re(result_re));

    //  Read / Write the control reg

    wire status_re, status_we, status_ready;

    iomem #(.ADDR(ADDR_STATUS)) status_io (.ck(ck),
                            .valid(iomem_valid), .wstrb(iomem_wstrb), .addr(iomem_addr),
                            .ready(status_ready), .we(status_we), .re(status_re));

    reg [31:0] rd_status;

    always @(posedge ck) begin
        if (status_we)
            control_reg <= iomem_wdata[(CONTROL_W-1):0];
        if (status_re)
            if (iomem_addr[2])
                rd_status <= capture;
            else
                rd_status[4:0] <= { 3'h0, error, done };
        else
            rd_status <= 0;
    end

    assign iomem_rdata = rd_result | rd_status;
    assign iomem_ready = coef_ready | result_ready | status_ready | reset_ready | input_ready;

endmodule

//  FIN
