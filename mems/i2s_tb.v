
`default_nettype none
`timescale 1ns / 100ps

module i2s_tb();

// Signals
reg clock = 1;

initial begin
    $dumpfile("i2s.vcd");
    $dumpvars(0, i2s_tb);
    sdi <= 0;
    #500000 $finish;
end

// Clock ~= 12Mhz
always #84 clock <= !clock;

// Generate the I2S timing signals

wire sck;
wire ws;
wire [5:0] frame_posn;
I2S_CLOCK i2s_ck(.ck(clock), .sck(sck), .ws(ws), .frame_posn(frame_posn));

// input data simulation

reg sdi;
// 32-bit audio word
reg [31:0] audio = 0;

always @(negedge sck) begin
    sdi <= audio[31];
end

reg [31:0] signal = 32'h82340000;

always @(posedge sck) begin
    if (frame_posn == 0) begin
        audio <= signal;
        signal <= signal + 32'h10000;
    end else if (frame_posn == 32) begin
        audio <= signal;
        signal <= signal + 32'h10000;
    end else begin
        audio <= audio << 1;
    end
end

// Read the audio data

wire [15:0] left;
wire [15:0] right;

I2S_RX i2s(.sck(sck), .ws(ws), .frame_posn(frame_posn), .sd(sdi), .left(left), .right(right));

//  Test the TX stage

wire sdo;

I2S_TX i2s_tx (.sck(sck), .ws(ws), .frame_posn(frame_posn), .left(left), .right(right), .sd(sdo));

//  Clock the Output into an Rx to see if it works back-to-back

wire [15:0] out_left;
wire [15:0] out_right;

I2S_RX i2s_rx_out(.sck(sck), .ws(ws), .frame_posn(frame_posn), .sd(sdo), .left(out_left), .right(out_right));

endmodule

