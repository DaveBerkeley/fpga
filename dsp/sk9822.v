
module sk9822_peripheral(
    input wire clk,
    input wire resetn,
	input wire iomem_valid,
	output reg iomem_ready,
	input wire [3:0] iomem_wstrb,
	input wire [31:0] iomem_addr,
	input wire [31:0] iomem_wdata,
	output reg [31:0] iomem_rdata,
    output reg led_ck,
    output reg led_data
);

    parameter ADDR = 16'h4000;

    reg ioram_we = 0;
    wire [3:0] ioram_waddr;
    wire [31:0] ioram_wdata;
    wire ioram_re;
    wire [3:0] ioram_raddr;
    wire [31:0] ioram_rdata;

    initial iomem_rdata = 0;

    dpram #(.BITS(32), .SIZE(16)) ioram (.clk(clk),
        .we(ioram_we), .waddr(ioram_waddr), .wdata(ioram_wdata),
        .re(ioram_re), .raddr(ioram_raddr), .rdata(ioram_rdata)
    );

    reg we = 0;
    wire [3:0] waddr;
    wire [31:0] wdata;
    wire re;
    wire [3:0] raddr;
    wire [31:0] rdata;

    dpram #(.BITS(32), .SIZE(16)) ram_ (.clk(clk),
        .we(we), .waddr(waddr), .wdata(wdata),
        .re(re), .raddr(raddr), .rdata(rdata)
    );

    led_sk9822 led_array (.clk(clk), .led_data(led_data), .led_ck(led_ck), .re(re), .raddr(raddr), .rdata(rdata[23:0]));

    initial iomem_ready = 0;

    wire dpram_en;
    assign dpram_en = iomem_valid && !iomem_ready && (iomem_addr[31:16] == ADDR);

	always @(posedge clk) begin
		if (resetn) begin
            if (iomem_ready)
    			iomem_ready <= 0;

            if (dpram_en) begin
				iomem_ready <= 1;
                we <= | iomem_wdata;
				iomem_rdata <= 32'h12345678;
            end else begin
                we <= 0;
				iomem_rdata <= 0;
			end
		end
	end

    assign waddr = iomem_addr[5:2];
    assign wdata = iomem_wdata;

endmodule


