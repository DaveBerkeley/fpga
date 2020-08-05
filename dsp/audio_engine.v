
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
    localparam ADDR_INPUT  = ADDR + 8'h04;

    localparam CHANNELS = 8;
    localparam FRAMES = 256;

    localparam CODE = 256; // but there are 2 banks of this
    localparam CODE_W = $clog2(CODE);
    localparam COEF_W = CODE_W + 1; // includes 2 banks

    localparam CHAN_W = $clog2(CHANNELS);
    localparam FRAME_W = $clog2(FRAMES);
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

    wire reset;
    assign reset = !((!wb_rst) && (resetx == 2'b10));

    reg [(FRAME_W-1):0] frame_counter = 0;
    wire [(FRAME_W-1):0] frame;

    //  Control Register

    reg [FRAME_W-1:0] control_reg_frame = 0;
    reg allow_audio_writes = 0;
    reg spl_reset = 0;

    assign frame = allow_audio_writes ? control_reg_frame : frame_counter;

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

    wire start_of_frame;
    assign start_of_frame = ws & (frame_posn == 0);

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

    // Delay the I2S data input sample point from the start of the clock
    wire i2s_sample;
    pipe #(.LENGTH(I2S_DIVIDER / 3)) sd_sample (.ck(ck), .in(i2s_en), .out(i2s_sample));

    i2s_rx #(.WIDTH(I2S_BIT_WIDTH)) 
    rx_0(.ck(ck), .sample(i2s_sample), 
            .frame_posn(frame_posn), .sd(sd_in0), .left(mic_0), .right(mic_1));
    i2s_rx #(.WIDTH(I2S_BIT_WIDTH)) 
    rx_1(.ck(ck), .sample(i2s_sample), 
            .frame_posn(frame_posn), .sd(sd_in1), .left(mic_2), .right(mic_3));
    i2s_rx #(.WIDTH(I2S_BIT_WIDTH)) 
    rx_2(.ck(ck), .sample(i2s_sample), 
            .frame_posn(frame_posn), .sd(sd_in2), .left(mic_4), .right(mic_5));
    i2s_rx #(.WIDTH(I2S_BIT_WIDTH)) 
    rx_3(.ck(ck), .sample(i2s_sample), 
            .frame_posn(frame_posn), .sd(sd_in3), .left(mic_6), .right(mic_7));

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
    //
    //  At start_of_frame the mic_x input from the I2S input
    //  is written into the audio RAM.
    //  
    //  The sequencer is then reset to start the DSP command sequence.

    function [15:0] get_source(input [2:0] chan,
        input [15:0] s0,
        input [15:0] s1,
        input [15:0] s2,
        input [15:0] s3,
        input [15:0] s4,
        input [15:0] s5,
        input [15:0] s6,
        input [15:0] s7
    );
 
        begin
            case (chan)
                0   :   get_source = s0;
                1   :   get_source = s1;
                2   :   get_source = s2;
                3   :   get_source = s3;
                4   :   get_source = s4;
                5   :   get_source = s5;
                6   :   get_source = s6;
                7   :   get_source = s7;
            endcase
        end

    endfunction

    function [15:0] mic_source(input [(CHAN_W-1):0] chan);
 
        begin
            mic_source = get_source(chan, mic_0, mic_1, mic_2, mic_3, mic_4, mic_5, mic_6, mic_7);
        end

    endfunction

    always @(posedge ck) begin
        // Check that the host processor isn't in write mode
        if (!allow_audio_writes) begin

            if (start_of_frame) begin
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

    wire [CODE_W-1:0] code_raddr;

    wire coef_we;
    wire [31:0] coef_rdata;
    wire [COEF_W-1:0] coef_waddr;
    wire [COEF_W-1:0] coef_raddr;

    reg bank_addr = 0;
    reg bank_done = 0;

    assign coef_we = wb_dbus_we & coef_cyc;
    assign coef_waddr = { !bank_addr, wb_dbus_adr[CODE_W+2-1:2] };
    assign coef_raddr = { bank_addr, code_raddr };

    dpram #(.BITS(32), .SIZE(CODE*2))
    coef (
        .ck(ck),
        .we(coef_we),
        .waddr(coef_waddr),
        .wdata(wb_dbus_dat),
        .re(1'h1),
        .raddr(coef_raddr),
        .rdata(coef_rdata)
    );

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

    wire [(CHAN_W-1):0] seq_wr_addr;
    wire [15:0] seq_audio;
    wire seq_we;
    wire error;
    wire seq_done;
    wire [31:0] capture;

    sequencer #(.CHAN_W(CHAN_W), .FRAME_W(FRAME_W), .AUDIO_W(AUDIO_W), .CODE_W(CODE_W))
    seq (
        .ck(ck),
        .rst(reset),
        .frame(frame),
        .coef_addr(code_raddr),
        .coef_data(coef_rdata), 
        .audio_raddr(audio_raddr),
        .audio_in(audio_rdata),
        .out_addr(seq_wr_addr),
        .out_audio(seq_audio),
        .out_we(seq_we),
        .done(seq_done),
        .error(error), 
        .capture_out(capture)
    );

    //  write sequencer output to the left & right output registers

    localparam LEFT_CHAN  = 0;
    localparam RIGHT_CHAN = 1;

    always @(posedge ck) begin
        if (seq_we) begin

            if (seq_wr_addr[0] == LEFT_CHAN) begin
                left <= seq_audio;
            end

            if (seq_wr_addr[0] == RIGHT_CHAN) begin
                right <= seq_audio;
            end

        end
    end

    //  Measure peak audio level on inputs

    wire spl_en;
    wire decay_en;
    wire [15:0] spl_0;
    wire [15:0] spl_1;
    wire [15:0] spl_2;
    wire [15:0] spl_3;
    wire [15:0] spl_4;
    wire [15:0] spl_5;
    wire [15:0] spl_6;
    wire [15:0] spl_7;

    assign spl_en = 1;// mic_x is updated once a frame
    assign decay_en = frame[3] && start_of_frame;

    spl #(.WIDTH(16))
        spl0 (.ck(ck), .rst(spl_reset), .peak_en(spl_en), .decay_en(decay_en), .in(mic_0), .out(spl_0));
    spl #(.WIDTH(16))
        spl1 (.ck(ck), .rst(spl_reset), .peak_en(spl_en), .decay_en(decay_en), .in(mic_1), .out(spl_1));
    spl #(.WIDTH(16))
        spl2 (.ck(ck), .rst(spl_reset), .peak_en(spl_en), .decay_en(decay_en), .in(mic_2), .out(spl_2));
    spl #(.WIDTH(16))
        spl3 (.ck(ck), .rst(spl_reset), .peak_en(spl_en), .decay_en(decay_en), .in(mic_3), .out(spl_3));
    spl #(.WIDTH(16))
        spl4 (.ck(ck), .rst(spl_reset), .peak_en(spl_en), .decay_en(decay_en), .in(mic_4), .out(spl_4));
    spl #(.WIDTH(16))
        spl5 (.ck(ck), .rst(spl_reset), .peak_en(spl_en), .decay_en(decay_en), .in(mic_5), .out(spl_5));
    spl #(.WIDTH(16))
        spl6 (.ck(ck), .rst(spl_reset), .peak_en(spl_en), .decay_en(decay_en), .in(mic_6), .out(spl_6));
    spl #(.WIDTH(16))
        spl7 (.ck(ck), .rst(spl_reset), .peak_en(spl_en), .decay_en(decay_en), .in(mic_7), .out(spl_7));
 
    function [15:0] spl_src(input [(CHAN_W-1):0] chan);

        begin
            spl_src = get_source(chan, spl_0, spl_1, spl_2, spl_3, spl_4, spl_5, spl_6, spl_7);
        end

    endfunction
    
    wire spl_xfer_run;
    wire [15:0] spl_xfer_data_in;
    wire [15:0] spl_xfer_data_out;
    wire [(CHAN_W-1):0] spl_xfer_addr;
    wire spl_xfer_we;
    wire spl_xfer_done;
    /* verilator lint_off UNUSED */
    wire spl_xfer_busy;
    /* verilator lint_on UNUSED */

    assign spl_xfer_run = seq_done;
    assign spl_xfer_data_in = spl_src(spl_xfer_addr);

    spl_xfer #(.WIDTH(16), .ADDR_W(CHAN_W))
    spl_xfer (
        .ck(ck),
        .rst(reset),
        .run(spl_xfer_run),
        .data_in(spl_xfer_data_in),
        .data_out(spl_xfer_data_out),
        .addr(spl_xfer_addr),
        .we(spl_xfer_we),
        .done(spl_xfer_done),
        .busy(spl_xfer_busy)
    );

    wire done;
    assign done = spl_xfer_done;

    //  Write Results to DP_RAM.
    //
    //  First the sequencer output is written to addr 0..7
    //  Then the spl data is written to addr 8..15

    wire [CHAN_W:0] result_raddr;

    assign result_raddr = wb_dbus_adr[(CHAN_W+2):2];

    wire result_ack, result_cyc;

    wire [CHAN_W:0] result_waddr;
    wire [15:0] result_wdata;
    wire result_we;

    assign result_we = seq_we | spl_xfer_we;
    assign result_waddr = spl_xfer_we ? { 1'b1, spl_xfer_addr } : { 1'b0, seq_wr_addr };
    assign result_wdata = spl_xfer_we ? spl_xfer_data_out : seq_audio;

    chip_select #(.ADDR(ADDR_RESULT)) 
    cs_result(
        .wb_ck(ck),
        .addr(cs_adr),
        .wb_cyc(wb_dbus_cyc),
        .wb_rst(wb_rst),
        .ack(result_ack),
        .cyc(result_cyc)
    );

    wire [15:0] result_out;

    dpram #(.BITS(16), .SIZE(CHANNELS*2)) 
    audio_out (.ck(ck),
        .we(result_we), 
        .waddr(result_waddr), 
        .wdata(result_wdata),
        .re(!wb_dbus_we), 
        .raddr(result_raddr), 
        .rdata(result_out)
    );

    wire [31:0] result_rdt;

    assign result_rdt = (result_cyc & !wb_dbus_we) ? { 16'h0, result_out } : 0;

    //  Read / Write the control reg
    //
    //  Provides : 0 control_reg r/w
    //             1 status_reg  r
    //             2 capture_reg r
    //             3 end_of_cmd  w

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

    wire [1:0] status_addr;
    wire status_we;
    wire status_re;

    assign status_addr = wb_dbus_adr[3:2];
    assign status_we = status_cyc & wb_dbus_we;
    assign status_re = status_cyc & !wb_dbus_we;
 
    always @(posedge ck) begin

        if (status_we & (status_addr == 0)) begin
            allow_audio_writes <= wb_dbus_dat[0];
            spl_reset <= wb_dbus_dat[1];
            control_reg_frame <= wb_dbus_dat[FRAME_W+2-1:2];
        end

        if (status_we & (status_addr == 3)) begin
            // End of Command request : ie request bank switch
            bank_done <= 0;
            if (allow_audio_writes) begin
                reset_req <= 1;
            end
        end

        if (reset & !bank_done) begin
            // switch banks
            bank_done <= 1;
            bank_addr <= !bank_addr; 
        end

        if (reset_req) begin
            reset_req <= 0;
        end

    end

    wire [31:0] control_reg;
    assign control_reg =  { { (32-(FRAME_W+1)){ 1'b0 } }, control_reg_frame, allow_audio_writes };

    function [31:0] sreg_rdt(input [1:0] s_addr);

        case (s_addr)
            0   :   sreg_rdt = control_reg;
            1   :   sreg_rdt = { 29'h0, bank_done, error, done };
            2   :   sreg_rdt = capture;
            3   :   sreg_rdt = 32'h0;
        endcase

    endfunction

    wire [31:0] status_rdt;

    assign status_rdt = status_re ? sreg_rdt(status_addr) : 0;

    //  OR the ACK and RST signals together

    assign ack = result_ack | status_ack | coef_ack | input_ack;
    assign rdt = result_rdt | status_rdt;
    assign ready = done;

    //  Test output

    assign test[0] = done;
    assign test[1] = reset;
    assign test[2] = seq_done;
    assign test[3] = spl_xfer_done;
    assign test[4] = spl_reset;
    assign test[5] = spl_xfer_we;
    assign test[6] = ck;
    assign test[7] = 0;

endmodule

//  FIN
