
`default_nettype none

module i2s_offset
#(parameter WIDTH=4)
(
    input wire ck,
    input wire i2s_en,
    input wire [WIDTH-1:0] offset,
    output wire en
);

    reg [WIDTH-1:0] counter = 0;

    always @(posedge ck) begin

        if (i2s_en) begin
            counter <= 0;
        end else begin
            counter <= counter + 1;
        end

    end

    assign en = offset == counter;


endmodule

   /*
    *   Audio Perihperal
    */

module audio_engine (
    input wire ck,

    // CPU bus interface
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

    // DMA interface
    output reg dma_cyc,
    output reg dma_we,
    output reg [3:0] dma_sel,
    output reg [31:0] dma_adr,
    output reg [31:0] dma_dat,
    /* verilator lint_off UNUSED */
    input wire dma_ack,
    input wire [31:0] dma_rdt,
    /* verilator lint_on UNUSED */
    // DMA status
    output wire dma_done,
    output wire dma_match,

    //  I2S interface
    output wire sck,    // I2S clock
    output wire ws,     // I2S word select
    output wire sd_out0, // I2S data out
    output wire sd_out1, // I2S data out
    input wire sd_in0,  // I2S data in
    input wire sd_in1,  // I2S data in
    input wire sd_in2,  // I2S data in
    input wire sd_in3,  // I2S data in

    input wire ext_sck, // I2S ext sync
    input wire ext_ws,  // I2S ext sync

    output wire ready,
    output wire [7:0] test
);

    parameter CK_HZ = 32000000;

    parameter                ADDR = 8'h60;

    localparam ADDR_COEF   = ADDR;
    localparam ADDR_RESULT = ADDR + 8'h01;
    localparam ADDR_STATUS = ADDR + 8'h02;
    localparam ADDR_INPUT  = ADDR + 8'h04;
    localparam ADDR_DMA    = ADDR + 8'h05;

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

    assign frame = allow_audio_writes ? control_reg_frame : frame_counter;

    //  I2S clock generation

    wire i2s_clock;

    // Divide the clock down to 2MHz
    // Gives 2e6/64 = 31250 Hz frame rate
    /* verilator lint_off WIDTH */
    //localparam [4:0] I2S_DIVIDER = CK_HZ / (64 * 31250);
`ifdef MAKE_HIFI
    localparam [5:0] I2S_DIVIDER = 20; // CK_HZ / (32 * 41100);
`endif
    /* verilator lint_on WIDTH */
    assign i2s_clock = ck;

    wire [5:0] frame_posn;
    wire i2s_en;
    wire i2s_external;

    i2s_dual #(.DIVIDER(I2S_DIVIDER))
    i2s_dual(
        .ck(i2s_clock),
        .rst(wb_rst),
        .ext_sck(ext_sck),
        .ext_ws(ext_ws),
        .en(i2s_en),
        .sck(sck),
        .ws(ws),
        .frame_posn(frame_posn),
        .external(i2s_external)
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

    localparam MIC_W = 24;

    /* verilator lint_off UNUSED */
    wire [MIC_W-1:0] mic_0;
    wire [MIC_W-1:0] mic_1;
    wire [MIC_W-1:0] mic_2;
    wire [MIC_W-1:0] mic_3;
    wire [MIC_W-1:0] mic_4;
    wire [MIC_W-1:0] mic_5;
    wire [MIC_W-1:0] mic_6;
    wire [MIC_W-1:0] mic_7;
    /* verilator lint_on UNUSED */

    // Delay the I2S data input sample point from the start of the clock
    wire i2s_in_sample;
    wire i2s_out_sample;
    reg [3:0] i2s_in_offset = 0;
    reg [3:0] i2s_out_offset = 0;

    i2s_offset #(.WIDTH(4))
    i2s_offset_in(
        .ck(ck),
        .i2s_en(i2s_en),
        .offset(i2s_in_offset),
        .en(i2s_in_sample)
    );

    i2s_offset #(.WIDTH(4))
    i2s_offset_out(
        .ck(ck),
        .i2s_en(i2s_en),
        .offset(i2s_out_offset),
        .en(i2s_out_sample)
    );

    `ifdef MAKE_HIFI
        localparam I2S_BITS = 32;
    `endif
    `ifdef MAKE_DSP
        localparam I2S_BITS = 64;
    `endif

    i2s_rx #(.BITS(MIC_W), .CLOCKS(I2S_BITS)) 
    rx_0(.ck(ck), .sample(i2s_in_sample), 
            .frame_posn(frame_posn), .sd(sd_in0), .left(mic_0), .right(mic_1));
    i2s_rx #(.BITS(MIC_W), .CLOCKS(I2S_BITS))
    rx_1(.ck(ck), .sample(i2s_in_sample), 
            .frame_posn(frame_posn), .sd(sd_in1), .left(mic_2), .right(mic_3));
    i2s_rx #(.BITS(MIC_W), .CLOCKS(I2S_BITS))
    rx_2(.ck(ck), .sample(i2s_in_sample), 
            .frame_posn(frame_posn), .sd(sd_in2), .left(mic_4), .right(mic_5));
    i2s_rx #(.BITS(MIC_W), .CLOCKS(I2S_BITS))
    rx_3(.ck(ck), .sample(i2s_in_sample), 
            .frame_posn(frame_posn), .sd(sd_in3), .left(mic_6), .right(mic_7));

    //  I2S Output

    reg [15:0] left_0 = 0;
    reg [15:0] right_0 = 0;
    reg [15:0] left_1 = 0;
    reg [15:0] right_1 = 0;

    i2s_tx #(.CLOCKS(I2S_BITS)) tx_0(
        .ck(ck),
        .en(i2s_out_sample),
        .frame_posn(frame_posn),
        .left(left_0),
        .right(right_0),
        .sd(sd_out0)
    );

    i2s_tx #(.CLOCKS(I2S_BITS)) tx_1(
        .ck(ck),
        .en(i2s_out_sample),
        .frame_posn(frame_posn),
        .left(left_1),
        .right(right_1),
        .sd(sd_out1)
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

    localparam MIC_SHIFT = 0;
    localparam MIC_HI = MIC_W-(1+MIC_SHIFT);
    localparam MIC_LO = MIC_W-(16+MIC_SHIFT);

    function [15:0] mic_source(input [(CHAN_W-1):0] chan);
 
        begin
            mic_source = get_source(chan,
                mic_0[MIC_HI:MIC_LO],
                mic_1[MIC_HI:MIC_LO],
                mic_2[MIC_HI:MIC_LO],
                mic_3[MIC_HI:MIC_LO],
                mic_4[MIC_HI:MIC_LO],
                mic_5[MIC_HI:MIC_LO],
                mic_6[MIC_HI:MIC_LO],
                mic_7[MIC_HI:MIC_LO]
            );
        end

    endfunction

    //  Write microphone data into DP_RAM

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

    localparam LCHAN_0 = 0;
    localparam RCHAN_0 = 1;
    localparam LCHAN_1 = 2;
    localparam RCHAN_1 = 3;

    always @(posedge ck) begin
        if (seq_we) begin

            case (seq_wr_addr[1:0])
                LCHAN_0 :   left_0  <= seq_audio;
                RCHAN_0 :   right_0 <= seq_audio;
                LCHAN_1 :   left_1  <= seq_audio;
                RCHAN_1 :   right_1 <= seq_audio;
            endcase

        end
    end

    wire done;
    assign done = seq_done;

    //  Write Results to DP_RAM.
    //
    //  Sequencer output is written to addr 0..7

    wire [CHAN_W:0] result_raddr;

    assign result_raddr = wb_dbus_adr[(CHAN_W+2):2];

    wire result_ack, result_cyc;

    wire [CHAN_W:0] result_waddr;
    wire [15:0] result_wdata;
    wire result_we;

    assign result_we = seq_we;
    assign result_waddr = { 1'b0, seq_wr_addr };
    assign result_wdata = seq_audio;

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
    //             4 i2s_offsets r/w

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

    wire [2:0] status_addr;
    wire status_we;
    wire status_re;

    assign status_addr = wb_dbus_adr[4:2];
    assign status_we = status_cyc & wb_dbus_we;
    assign status_re = status_cyc & !wb_dbus_we;
 
    always @(posedge ck) begin

        if (status_we & (status_addr == 0)) begin
            allow_audio_writes <= wb_dbus_dat[0];
            control_reg_frame <= wb_dbus_dat[FRAME_W+2-1:2];
        end

        if (status_we & (status_addr == 3)) begin
            // End of Command request : ie request bank switch
            bank_done <= 0;
            if (allow_audio_writes) begin
                reset_req <= 1;
            end
        end

        if (status_we & (status_addr == 4)) begin
            i2s_in_offset  <= wb_dbus_dat[3:0];
            i2s_out_offset <= wb_dbus_dat[7:4];
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
    assign control_reg =  { 
        { (32-(FRAME_W+2)){ 1'b0 } }, 
        control_reg_frame, 
        i2s_external, 
        allow_audio_writes 
    };

    function [31:0] sreg_rdt(input [2:0] s_addr);

        case (s_addr)
            0   :   sreg_rdt = control_reg;
            1   :   sreg_rdt = { 29'h0, bank_done, error, done };
            2   :   sreg_rdt = capture;
            3   :   sreg_rdt = 32'h0;
            4   :   sreg_rdt = { 24'h0, i2s_out_offset, i2s_in_offset };
        endcase

    endfunction

    wire [31:0] status_rdt;

    assign status_rdt = status_re ? sreg_rdt(status_addr) : 0;

    //  DMA Test

`ifdef USE_DMA

    localparam XFER_ADDR_W = 3;
    localparam XFER_DATA_W = 16;

    wire [31:0] dma_dbus_rdt;
    wire dma_dbus_ack;
    wire xfer_done;
    wire [XFER_ADDR_W-1:0] xfer_adr;
    /* verilator lint_off UNUSED */
    wire block_done;
    wire xfer_re;
    /* verilator lint_on UNUSED */
    wire xfer_match;

    assign dma_done = xfer_done;
    assign dma_match = xfer_match;

    wire [15:0] xfer_dat;
    assign xfer_dat = mic_source(xfer_adr);

    wire xfer_block;
    assign xfer_block = start_of_frame; 

    dma #(.ADDR(ADDR_DMA), .WIDTH(8), .XFER_ADDR_W(XFER_ADDR_W))
    dma (
        .wb_clk(ck),
        .wb_rst(wb_rst),
        .wb_dbus_cyc(wb_dbus_cyc),
        .wb_dbus_we(wb_dbus_we),
        .wb_dbus_adr(wb_dbus_adr),
        .wb_dbus_dat(wb_dbus_dat),
        .dbus_rdt(dma_dbus_rdt),
        .dbus_ack(dma_dbus_ack),
        .xfer_block(xfer_block),
        .block_done(block_done),
        .xfer_done(xfer_done),
        .xfer_match(xfer_match),
        .xfer_adr(xfer_adr),
        .xfer_re(xfer_re),
        .xfer_dat(xfer_dat),
        .dma_cyc(dma_cyc),
        .dma_we(dma_we),
        .dma_sel(dma_sel),
        .dma_adr(dma_adr),
        .dma_dat(dma_dat),
        .dma_ack(dma_ack),
        .dma_rdt(dma_rdt)
    );
`else   // USE_DMA

    initial begin
        dma_cyc = 0;
        dma_we = 0;
        dma_sel = 0;
        dma_dat = 0;
        dma_adr = 0;
    end

    wire [31:0] dma_dbus_rdt;
    wire dma_dbus_ack;
    assign dma_dbus_rdt = 0;
    assign dma_dbus_ack = 0;
    assign dma_done = 0;
    assign dma_match = 0;

`endif // USE_DMA
    
    //  OR the ACK and RST signals together

    assign ack = result_ack | status_ack | dma_dbus_ack | coef_ack | input_ack;
    assign rdt = result_rdt | status_rdt | dma_dbus_rdt;
    assign ready = done;

    //  Test output

    assign test[0] = sck;
    assign test[1] = ws;
    assign test[2] = sd_in0;
    assign test[3] = sd_in1;
    assign test[4] = ext_sck; // sd_in2;
    assign test[5] = ext_ws; // sd_in3;
    assign test[6] = i2s_external;
    assign test[7] = 0; // not working?

endmodule

//  FIN
