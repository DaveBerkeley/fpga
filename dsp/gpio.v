
   /*
    *
    */

module gpio(
    input wire ck,
    input wire resetn,
	input wire iomem_valid,
	output reg iomem_ready,
	input wire [3:0] iomem_wstrb,
	input wire [31:0] iomem_addr,
	input wire [31:0] iomem_wdata,
	output reg [31:0] iomem_rdata,
    output wire [7:0] leds
);

    parameter ADDR = 16'h0300;

	reg [31:0] gpio_reg;
	assign leds = gpio_reg;

    wire gpio_reg_en;

    initial iomem_ready = 0;

    assign gpio_reg_en  = iomem_valid && !iomem_ready && (iomem_addr[31:16] == ADDR);

	always @(posedge ck) begin
		if (!resetn) begin
			gpio_reg <= 0;
		end else begin
            if (iomem_ready)
    			iomem_ready <= 0;
			if (gpio_reg_en) begin
				iomem_ready <= 1;
				iomem_rdata <= gpio_reg;
				if (iomem_wstrb[0]) gpio_reg[ 7: 0] <= iomem_wdata[ 7: 0];
				if (iomem_wstrb[1]) gpio_reg[15: 8] <= iomem_wdata[15: 8];
				if (iomem_wstrb[2]) gpio_reg[23:16] <= iomem_wdata[23:16];
				if (iomem_wstrb[3]) gpio_reg[31:24] <= iomem_wdata[31:24];
			end
		end
	end

endmodule


