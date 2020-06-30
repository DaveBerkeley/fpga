
   /*
    *   Audio Perihperal
    */

module audio_engine (
    input wire ck,
    input wire rst,
    /* verilator lint_off UNUSED */
	input wire iomem_valid,
    /* verilator lint_on UNUSED */
	output reg iomem_ready,
    /* verilator lint_off UNUSED */
	input wire [3:0] iomem_wstrb,
	input wire [31:0] iomem_addr,
	input wire [31:0] iomem_wdata,
	output reg [31:0] iomem_rdata,
    /* verilator lint_on UNUSED */
    output reg i2s_ck,
    output reg i2s_ws
);

    parameter ADDR = 16'h6000;

    localparam ADDR_COEF   = ADDR;
    localparam ADDR_RESULT = ADDR + 16'h0100;
    localparam ADDR_STATUS = ADDR + 16'h0200;

    wire done;
    reg [(FRAME_W-1):0] frame = 4;

    initial iomem_ready = 0;
    initial iomem_rdata = 0;

    //  Drive the engine

    localparam CHANNELS = 16;
    localparam FRAMES = 32;
    localparam CODE = 256;
    localparam CHAN_W = $clog2(CHANNELS);
    localparam FRAME_W = $clog2(FRAMES);
    localparam CODE_W = $clog2(CODE);
    localparam AUDIO = CHANNELS * FRAMES;
    localparam AUDIO_W = $clog2(AUDIO);

    // Coef / Program DP RAM
    reg coef_we;
    wire [(CODE_W-1):0] coef_waddr;
    wire [31:0] coef_rdata;
    wire [(CODE_W-1):0] coef_raddr;

    dpram #(.BITS(32), .SIZE(CODE), .FNAME("coef.data"))
        coef (.ck(ck), 
            .we(coef_we), .waddr(coef_waddr), .wdata(iomem_wdata),
            .re(1'h1), .raddr(coef_raddr), .rdata(coef_rdata));

    assign coef_waddr = iomem_addr[(2+CODE_W-1):2];

    // Audio Input DP RAM

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

    sequencer #(.CHAN_W(CHAN_W), .FRAME_W(FRAME_W)) seq (
            .ck(ck), .rst(rst), .frame(frame),
            .coef_addr(coef_raddr), .coef_data(coef_rdata), 
            .audio_raddr(audio_raddr), .audio_in(audio_rdata),
            .out_addr(out_wr_addr), .out_audio(out_audio), .out_we(out_we),
            .done(done), .error(error));

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

    initial iomem_ready = 0;

    wire coef_en, result_en, status_en;

    assign coef_en   = iomem_valid && !iomem_ready && (iomem_addr[31:16] == ADDR_COEF);
    assign result_en = iomem_valid && !iomem_ready && (iomem_addr[31:16] == ADDR_RESULT);
    assign status_en = iomem_valid && !iomem_ready && (iomem_addr[31:16] == ADDR_STATUS);

	always @(posedge ck) begin
		if (rst) begin
            if (iomem_ready)
    			iomem_ready <= 0;

            if (coef_en) begin
				iomem_ready <= 1;
                coef_we <= | iomem_wstrb;
				iomem_rdata <= 32'h12345678;
            end else begin
                coef_we <= 0;
				iomem_rdata <= 0;
			end

            if (result_en) begin
				iomem_ready <= 1;
                result_re <= | iomem_wstrb;
				iomem_rdata <= { 16'h0, result_rdata };
            end else begin
                result_re <= 0;
				iomem_rdata <= 0;
			end

            if (status_en) begin
				iomem_ready <= 1;
				iomem_rdata <= { 30'h0, error, done };
            end else begin
				iomem_rdata <= 0;
			end

		end
	end

    initial i2s_ck = 0;
    initial i2s_ws = 0;

    always @(posedge ck) begin
        i2s_ck <= ck;
        i2s_ws <= ck;
    end

endmodule

