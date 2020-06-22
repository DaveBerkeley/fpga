
`default_nettype none
`timescale 1ns / 100ps

module i2s_tb();

wire sck;
wire ws;
reg sd;
wire [5:0] frame_posn;
wire [15:0] left;
wire [15:0] right;

I2S_CLOCK i2s_ck(.ck(clock), .sck(sck), .ws(ws), .frame_posn(frame_posn));
I2S_RX i2s(.sck(sck), .ws(ws), .frame_posn(frame_posn), .sd(sd), .left(left), .right(right));

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

// input data simulation

reg [31:0] audio = 0;

always @(negedge sck) begin
    # 1;
    sd <= audio[31];
end

reg [31:0] signal = 32'h82340000;

always @(posedge sck) begin
    if (frame_posn == 0) begin
        audio <= signal;
        # 1 signal <= signal + 32'h10000;
    end else if (frame_posn == 32) begin
        audio <= signal;
        # 1 signal <= signal + 32'h10000;
    end else begin
        audio <= audio << 1;
    end
end

//  Test the TX stage

wire i2s_out;

I2S_TX i2s_tx (.sck(sck), .ws(ws), .left(left), .right(right), .sd(i2s_out));

endmodule

