
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
    output wire [7:0] test
);

    parameter                ADDR = 16'h6000;

    localparam ADDR_COEF   = ADDR;
    localparam ADDR_RESULT = ADDR + 16'h0100;
    localparam ADDR_STATUS = ADDR + 16'h0200;
    localparam ADDR_RESET  = ADDR + 16'h0300;
    localparam ADDR_INPUT  = ADDR + 16'h0400;

    // Send an extended reset pulse to the audio engine

    reg [1:0] resetx = 0;

    always @(negedge ck) begin
        if (reset_req)
            resetx <= 0;
        else 
           if (resetx != 2'b11)
                resetx <= resetx + 1;
    end

    wire reset;
    assign reset = rst && (resetx == 2'b11);

    wire done;
    // TODO : increment audio frame 
    reg [(FRAME_W-1):0] frame = 0;

    //  Control Register

    // bit-0 : set to allow writes to the audio input RAM
    reg [4:0] control_reg = 0;

    wire allow_audio_writes;
    assign allow_audio_writes = control_reg[0];
    wire [3:0] test_select;
    assign test_select = control_reg[4:1];

    //  Drive the engine

    localparam CHANNELS = 16;
    localparam FRAMES = 32;
    localparam CODE = 256;
    localparam CHAN_W = $clog2(CHANNELS);
    localparam FRAME_W = $clog2(FRAMES);
    localparam CODE_W = $clog2(CODE);
    localparam AUDIO = CHANNELS * FRAMES;
    localparam AUDIO_W = $clog2(AUDIO);

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

    // TODO : connect I2S Rx to the RAM
    wire audio_we;
    wire [15:0] audio_wdata;
    wire [(AUDIO_W-1):0] audio_waddr;
    wire [15:0] audio_rdata;
    wire [(AUDIO_W-1):0] audio_raddr;

    dpram #(.BITS(16), .SIZE(AUDIO), .FNAME("audio.data")) 
        audio_in (.ck(ck), 
            .we(audio_we), .waddr(audio_waddr), .wdata(audio_wdata),
            .re(1'h1), .raddr(audio_raddr), .rdata(audio_rdata));

    // allow_audio_writes
    wire input_we;
    // TODO : allow writes from I2S hardware
    assign audio_we    = allow_audio_writes ? input_we : 0;
    assign audio_waddr = allow_audio_writes ? iomem_addr[10:2] : 9'h0;
    assign audio_wdata = allow_audio_writes ? iomem_wdata[15:0] : 16'h0;

    // Sequencer

    wire [3:0] out_wr_addr;
    wire [15:0] out_audio;
    wire out_we;
    wire error;

    /* verilator lint_off UNUSED */
    wire [7:0] seq_test;
    /* verilator lint_on UNUSED */

    sequencer #(.CHAN_W(CHAN_W), .FRAME_W(FRAME_W)) seq (
            .ck(ck), .rst(reset), .frame(frame),
            .coef_addr(coef_raddr), .coef_data(coef_rdata), 
            .audio_raddr(audio_raddr), .audio_in(audio_rdata),
            .out_addr(out_wr_addr), .out_audio(out_audio), .out_we(out_we),
            .done(done), .error(error), 
            .test_in(test_select[2:0]), .test_out(seq_test));

    //  Results RAM
    //  TODO : Also write results to I2S hardware

    reg result_re = 0;
    wire [15:0] result_rdata;
    wire [3:0] result_raddr;

    dpram #(.BITS(16), .SIZE(16))
        audio_out (.ck(ck), 
            .we(out_we), .waddr(out_wr_addr), .wdata(out_audio),
            .re(result_re), .raddr(result_raddr), .rdata(result_rdata));

    assign result_raddr = iomem_addr[5:2];

    // Interface the peripheral to the Risc-V bus

    wire coef_en, result_en, status_en, reset_en, input_en;

    assign coef_en   = rst && iomem_valid && !iomem_ready && (iomem_addr[31:16] == ADDR_COEF);
    assign result_en = rst && iomem_valid && !iomem_ready && (iomem_addr[31:16] == ADDR_RESULT);
    assign status_en = rst && iomem_valid && !iomem_ready && (iomem_addr[31:16] == ADDR_STATUS);
    assign reset_en  = rst && iomem_valid && !iomem_ready && (iomem_addr[31:16] == ADDR_RESET);
    assign input_en  = rst && iomem_valid && !iomem_ready && (iomem_addr[31:16] == ADDR_INPUT);

    reg reset_req = 0;

    reg [31:0] rd_result = 0;
    reg [31:0] rd_status = 0;

    assign iomem_rdata = rd_result | rd_status;

    reg coef_ready = 0, result_ready = 0, status_ready = 0, reset_ready = 0, input_ready = 0;

    assign iomem_ready = coef_ready | result_ready | status_ready | reset_ready | input_ready;

    assign coef_we = coef_en;
    assign input_we = input_en;

    always @(negedge ck) begin
        if (rst) begin

            if (result_re)
                result_re <= 0;

            result_ready <= 0;
            status_ready <= 0;
            reset_ready <= 0;
            input_ready <= 0;

            // Write to the coefficient RAM
            if (coef_ready)
                coef_ready <= 0;
            if (coef_en)
                coef_ready <= 1;

            // Write to the audio input RAM
            if (input_ready)
                input_ready <= 0;
            if (input_en)
                input_ready <= 1;

            // Read from the results RAM
            if (result_en) begin
                result_re <= 1;
                rd_result <= { 16'h0, result_rdata };
                result_ready <= 1;
            end else begin
                rd_result <= 0;
            end

            // Read the status
            if (status_en) begin
                rd_status <= { 29'h0, error, done, allow_audio_writes };
                if (| iomem_wstrb)
                    control_reg <= iomem_wdata[4:0];
                status_ready <= 1;
            end else begin
                rd_status <= 0;
            end

            // Reset the engine
            if (reset_en) begin
                reset_req <= | iomem_wstrb;
                reset_ready <= 1;
            end else begin
                reset_req <= 0;
            end

        end
    end

    //  Debug traces

    function [7:0] test_src();
        case (test_select[2:0])
            0 : test_src = { 3'b0, allow_audio_writes, audio_we, coef_en, coef_we, coef_ready }; 
            1 : test_src = { 3'b0, frame };
            2 : test_src = { 3'b0, input_en, input_ready, input_we, iomem_ready, iomem_valid };
            3 : test_src = { 3'b0, out_we, out_wr_addr };
            4 : test_src = 0;
            5 : test_src = 0;
            6 : test_src = 0;
            7 : test_src = 0;
        endcase
    endfunction

    /* verilator lint_off UNUSED */
    reg [7:0] test_out;
    /* verilator lint_on UNUSED */

    always @(posedge ck) begin
        if (test_select[3])
            test_out <= test_src();
        else
            test_out <= seq_test;
    end

    assign test = { ck, reset, done, test_out[4], test_out[3], test_out[2], test_out[1], test_out[0] };

endmodule

