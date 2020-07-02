
   /*
    *   Audio Perihperal
    */

module audio_engine (
    input wire ck,
    input wire rst,
    /* verilator lint_off UNUSED */
	input wire iomem_valid,
    /* verilator lint_on UNUSED */
	output wire iomem_ready,
    /* verilator lint_off UNUSED */
	input wire [3:0] iomem_wstrb,
	input wire [31:0] iomem_addr,
	input wire [31:0] iomem_wdata,
	output wire [31:0] iomem_rdata,
    /* verilator lint_on UNUSED */
    output wire [7:0] test
);

    parameter                ADDR = 16'h6000;

    localparam ADDR_COEF   = ADDR;
    localparam ADDR_RESULT = ADDR + 16'h0100;
    localparam ADDR_STATUS = ADDR + 16'h0200;
    localparam ADDR_RESET  = ADDR + 16'h0300;
    localparam ADDR_TEST   = ADDR + 16'h0400;

    wire done;
    reg [(FRAME_W-1):0] frame = 4;

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
    reg audio_we = 0;
    reg [15:0] audio_wdata = 0;
    reg [(AUDIO_W-1):0] audio_waddr = 0;
    wire [15:0] audio_rdata;
    wire [(AUDIO_W-1):0] audio_raddr;

    dpram #(.BITS(16), .SIZE(AUDIO), .FNAME("audio.data")) 
        audio_in (.ck(ck), 
            .we(audio_we), .waddr(audio_waddr), .wdata(audio_wdata),
            .re(1'h1), .raddr(audio_raddr), .rdata(audio_rdata));

    // Sequencer

    wire [3:0] out_wr_addr;
    wire [15:0] out_audio;
    wire out_we;
    wire error;

    wire reset;
    /* verilator lint_off UNUSED */
    wire [7:0] seq_test;
    /* verilator lint_on UNUSED */

    sequencer #(.CHAN_W(CHAN_W), .FRAME_W(FRAME_W)) seq (
            .ck(ck), .rst(reset), .frame(frame),
            .coef_addr(coef_raddr), .coef_data(coef_rdata), 
            .audio_raddr(audio_raddr), .audio_in(audio_rdata),
            .out_addr(out_wr_addr), .out_audio(out_audio), .out_we(out_we),
            .done(done), .error(error), .test(seq_test));

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

    wire coef_en, result_en, status_en, reset_en;

    assign coef_en   = rst && iomem_valid && !iomem_ready && (iomem_addr[31:16] == ADDR_COEF);
    assign result_en = rst && iomem_valid && !iomem_ready && (iomem_addr[31:16] == ADDR_RESULT);
    assign status_en = rst && iomem_valid && !iomem_ready && (iomem_addr[31:16] == ADDR_STATUS);
    assign reset_en  = rst && iomem_valid && !iomem_ready && (iomem_addr[31:16] == ADDR_RESET);

    reg reset_req = 0;

    reg [31:0] rd_result = 0;
    reg [31:0] rd_status = 0;

    assign iomem_rdata = rd_result | rd_status;

    reg coef_ready = 0;
    reg result_ready = 0, status_ready = 0, reset_ready = 0;

    assign iomem_ready = coef_ready | result_ready | status_ready | reset_ready;

    assign coef_we = coef_en;

	always @(negedge ck) begin
		if (rst) begin

            if (result_re)
                result_re <= 0;

            result_ready <= 0;
            status_ready <= 0;
            reset_ready <= 0;

            // Write to the coefficient RAM
            if (coef_ready)
                coef_ready <= 0;
            if (coef_en)
                coef_ready <= 1;

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
				rd_status <= { 30'h0, error, done };
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

    // Send an extended reset pulse to the audio engine

    reg [1:0] resetx = 0;

    always @(negedge ck) begin
        if (reset_req)
            resetx <= 0;
        else 
           if (resetx != 2'b11)
                resetx <= resetx + 1;
    end

    assign reset = rst && (resetx == 2'b11);

    //  Debug traces

    reg [6:0] testx;
    initial testx = 0;

    assign test = { testx, ck };

//coef_raddr result_raddr out_wr_addr

    always @(posedge ck) begin
        testx[0] <= iomem_valid;
        testx[1] <= done;
        testx[2] <= reset;
        testx[3] <= error;
        testx[4] <= seq_test[0];
        testx[5] <= seq_test[1];
        testx[6] <= seq_test[2];
    end

endmodule

