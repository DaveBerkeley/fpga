
`default_nettype none
`timescale 1ns / 100ps

module mems_tb(clk, sck, ws, bus, left, right);

output clk;
input sck, ws;
input [15:0] bus;
input left;
input right;

	// Signals
	reg clock = 1;

	// Setup Recording
	initial begin
		$dumpfile("mems.vcd");
		$dumpvars(0,mems_tb);
	end

	// Reset Pulse
	initial begin
		#500000 $finish;
	end

	// Clock
	always #84 clock <= !clock;

    assign clk = clock;

endmodule

