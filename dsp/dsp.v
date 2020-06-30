
   /*
    *
    */

module top (input wire CLK, output wire P1A1, output wire P1A2, output wire P1A3, output wire P1A4);

    wire ck;
    assign ck = CLK;

	reg [1:0] reset_cnt = 0;
	wire rst = & reset_cnt;

	always @(posedge ck) begin
        if (!rst)
    		reset_cnt <= reset_cnt + 1;
	end

	reg        iomem_valid = 0;
    /* verilator lint_off UNUSED */
	wire        iomem_ready;
    /* verilator lint_on UNUSED */
	reg [3:0]  iomem_wstrb = 0;
	reg [31:0] iomem_addr = 0;
	reg [31:0] iomem_wdata = 0;
    /* verilator lint_off UNUSED */
	wire [31:0] iomem_rdata;
    /* verilator lint_on UNUSED */

    wire i2s_ck;
    wire i2s_ws;

    audio_engine engine(.ck(ck), .rst(rst),
        .iomem_valid(iomem_valid),
        .iomem_ready(iomem_ready),
        .iomem_wstrb(iomem_wstrb),
        .iomem_addr(iomem_addr),
        .iomem_wdata(iomem_wdata),
        .iomem_rdata(iomem_rdata),
        .i2s_ck(i2s_ck),
        .i2s_ws(i2s_ws)
    );

    assign P1A1 = ck;
    assign P1A2 = iomem_valid;
    assign P1A3 = i2s_ws;
    assign P1A4 = i2s_ck;

endmodule

