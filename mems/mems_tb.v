
`default_nettype none
`timescale 1ns / 100ps

module mems_tb(clk, sck, ws);

output clk;
input sck, ws;

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

