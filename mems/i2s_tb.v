
`default_nettype none
`timescale 1ns / 100ps

module i2s_tb();

wire sck;
wire ws;
reg sd;
wire [5:0] bit_count;
wire [15:0] do;

I2S_CLOCK i2s_ck(clock, sck, ws, bit_count);
I2S_IN i2s(sck, ws, bit_count, sd, do, do);

// Signals
reg clock = 1;

initial begin
    $dumpfile("i2s.vcd");
    $dumpvars(0, i2s_tb);
    sd <= 0;
    #500000 $finish;
end

// Clock ~= 12Mhz
always #84 clock <= !clock;

// TODO : need better input data simulation

reg [31:0] audio = 0;

always @(negedge sck) begin
    # 1;
    sd <= audio[31];
end

reg [31:0] signal = 32'h81230000;

always @(posedge sck) begin
    if (bit_count == 0) begin
        audio <= signal;
        # 1 signal <= signal + 32'h10000;
    end else if (bit_count == 32) begin
        audio <= signal;
        # 1 signal <= signal + 32'h10000;
    end else begin
        audio <= audio << 1;
    end
end

endmodule

