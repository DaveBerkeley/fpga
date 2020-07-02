/*
 *  PicoSoC - A simple example SoC using PicoRV32
 *
 *  Copyright (C) 2017  Clifford Wolf <clifford@clifford.at>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

`ifdef PICOSOC_V
`error "icebreaker.v must be read before picosoc.v!"
`endif

`define PICOSOC_MEM ice40up5k_spram

module icebreaker (
	input clk,

	output ser_tx,
	input ser_rx,

	output led1,
	output led2,
	output led3,
	output led4,
	output led5,

	output ledr_n,
	output ledg_n,

	output flash_csb,
	output flash_clk,
	inout  flash_io0,
	inout  flash_io1,
	inout  flash_io2,
	inout  flash_io3,

    output i2s_sck,
    output i2s_ws,
    input i2s_d0,
    input i2s_d1,
    input i2s_d2,
    input i2s_d3,
    output i2s_out
);
	parameter integer MEM_WORDS = 32768;

	reg [5:0] reset_cnt = 0;
	wire resetn = &reset_cnt;

	always @(posedge clk) begin
		reset_cnt <= reset_cnt + !resetn;
	end

    // RAM Test

    reg ioram_we = 0;
    wire [3:0] ioram_waddr;
    wire [31:0] ioram_wdata;
    wire ioram_re;
    wire [3:0] ioram_raddr;
    /* verilator lint_off UNUSED */
    wire [31:0] ioram_rdata;
    /* verilator lint_on UNUSED */

    dpram #(.BITS(32), .SIZE(16)) ioram (.clk(clk),
        .we(ioram_we), .waddr(ioram_waddr), .wdata(ioram_wdata),
        .re(ioram_re), .raddr(ioram_raddr), .rdata(ioram_rdata)
    );

    //  Test using LEDs

    wire led_data;
    assign i2s_sck = led_data;
    wire led_ck;
    assign i2s_ws = led_ck;

    reg we = 0;
    wire [3:0] waddr;
    wire [31:0] wdata;
    wire re;
    wire [3:0] raddr;
    /* verilator lint_off UNUSED */
    wire [31:0] rdata;
    /* verilator lint_on UNUSED */

    dpram #(.BITS(32), .SIZE(16)) ram_ (.clk(clk),
        .we(we), .waddr(waddr), .wdata(wdata),
        .re(re), .raddr(raddr), .rdata(rdata)
    );

    led_sk9822 led_array (.clk(clk), .led_data(led_data), .led_ck(led_ck), .re(re), .raddr(raddr), .rdata(rdata[23:0]));

    //ram_write writer(.clk(clk), .we(we), .waddr(waddr), .wdata(wdata));

    reg test = 0;

    always @(posedge clk) begin
        test <= iomem_valid;
    end

    assign i2s_out = test;

    //  End Test using sk9822 LEDs

	wire [7:0] leds;

	assign led1 = leds[1];
	assign led2 = leds[2];
	assign led3 = leds[3];
	assign led4 = leds[4];
	assign led5 = leds[5];

	assign ledr_n = !leds[6];
	assign ledg_n = !leds[7];

	wire flash_io0_oe, flash_io0_do, flash_io0_di;
	wire flash_io1_oe, flash_io1_do, flash_io1_di;
	wire flash_io2_oe, flash_io2_do, flash_io2_di;
	wire flash_io3_oe, flash_io3_do, flash_io3_di;

	SB_IO #(
		.PIN_TYPE(6'b 1010_01),
		.PULLUP(1'b 0)
	) flash_io_buf [3:0] (
		.PACKAGE_PIN({flash_io3, flash_io2, flash_io1, flash_io0}),
		.OUTPUT_ENABLE({flash_io3_oe, flash_io2_oe, flash_io1_oe, flash_io0_oe}),
		.D_OUT_0({flash_io3_do, flash_io2_do, flash_io1_do, flash_io0_do}),
		.D_IN_0({flash_io3_di, flash_io2_di, flash_io1_di, flash_io0_di})
	);

    //  IO Memory interface

	wire        iomem_valid;
	reg         iomem_ready;
	wire [3:0]  iomem_wstrb;
	wire [31:0] iomem_addr;
	wire [31:0] iomem_wdata;
	reg  [31:0] iomem_rdata;

	reg [31:0] gpio;
	assign leds = gpio;

    wire gpio_en;
    wire dpram_en;

    assign gpio_en  = iomem_valid && !iomem_ready && (iomem_addr[31:16] == 16'h 0300);
    assign dpram_en = iomem_valid && !iomem_ready && (iomem_addr[31:16] == 16'h 4000);

	always @(posedge clk) begin
		if (!resetn) begin
			gpio <= 0;
		end else begin
            if (iomem_ready)
    			iomem_ready <= 0;
			if (gpio_en) begin
				iomem_ready <= 1;
				iomem_rdata <= gpio;
				if (iomem_wstrb[0]) gpio[ 7: 0] <= iomem_wdata[ 7: 0];
				if (iomem_wstrb[1]) gpio[15: 8] <= iomem_wdata[15: 8];
				if (iomem_wstrb[2]) gpio[23:16] <= iomem_wdata[23:16];
				if (iomem_wstrb[3]) gpio[31:24] <= iomem_wdata[31:24];
			end

            // Interface to DP RAM
			if (dpram_en) begin
				iomem_ready <= 1;
                we <= | iomem_wdata;
				iomem_rdata <= 32'h12345678;
            end else begin
                we <= 0;
			end
		end
	end

    assign waddr = iomem_addr[5:2];
    assign wdata = iomem_wdata;

    //  Processor Core

	picosoc #(
		.BARREL_SHIFTER(0),
		.ENABLE_MULDIV(0),
		.MEM_WORDS(MEM_WORDS)
	) soc (
		.clk          (clk         ),
		.resetn       (resetn      ),

		.ser_tx       (ser_tx      ),
		.ser_rx       (ser_rx      ),

		.flash_csb    (flash_csb   ),
		.flash_clk    (flash_clk   ),

		.flash_io0_oe (flash_io0_oe),
		.flash_io1_oe (flash_io1_oe),
		.flash_io2_oe (flash_io2_oe),
		.flash_io3_oe (flash_io3_oe),

		.flash_io0_do (flash_io0_do),
		.flash_io1_do (flash_io1_do),
		.flash_io2_do (flash_io2_do),
		.flash_io3_do (flash_io3_do),

		.flash_io0_di (flash_io0_di),
		.flash_io1_di (flash_io1_di),
		.flash_io2_di (flash_io2_di),
		.flash_io3_di (flash_io3_di),

		.irq_5        (1'b0        ),
		.irq_6        (1'b0        ),
		.irq_7        (1'b0        ),

		.iomem_valid  (iomem_valid ),
		.iomem_ready  (iomem_ready ),
		.iomem_wstrb  (iomem_wstrb ),
		.iomem_addr   (iomem_addr  ),
		.iomem_wdata  (iomem_wdata ),
		.iomem_rdata  (iomem_rdata )
	);
endmodule