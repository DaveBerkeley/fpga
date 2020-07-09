
   /*
    *
    */

module gpio(
    input wire ck,
    input wire rst,
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

    wire re, we;

    iomem #(.ADDR(ADDR)) io(.ck(ck), .rst(rst), 
        .valid(iomem_valid), .ready(iomem_ready), .wstrb(iomem_wstrb), .addr(iomem_addr), 
        .we(we), .re(re));

	always @(posedge ck) begin
		if (!rst) begin
			gpio_reg <= 0;
        end else begin
            if (we)
                gpio_reg <= iomem_wdata;
            if (re)
                iomem_rdata <= gpio_reg;
        end
    end
 
endmodule


