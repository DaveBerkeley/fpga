
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
always #42 clock <= !clock;

// Generate the I2S timing signals

wire sck;
wire ws;
wire [5:0] frame_posn;
wire [7:0] frame;
I2S_CLOCK i2s_ck(.ck(clock), .sck(sck), .ws(ws), .frame_posn(frame_posn), .frame(frame));

// input data simulation

reg sdi;
// 32-bit audio word
reg [31:0] audio = 0;

always @(negedge sck) begin
    sdi <= audio[31];
end

reg [31:0] signal_l = 32'h82340000;
reg [31:0] signal_r = 32'h12340000;

always @(posedge sck) begin
    if (frame_posn == 0) begin
        audio <= signal_l;
        signal_l <= signal_l + 32'h20000;
    end else if (frame_posn == 32) begin
        audio <= signal_r;
        signal_r <= signal_r + 32'h100000;
    end else begin
        audio <= audio << 1;
    end
end

// Read the audio data

wire [15:0] left;
wire [15:0] right;

I2S_RX i2s(.sck(sck), .ws(ws), .frame_posn(frame_posn), .sd(sdi), .left(left), .right(right));

//  Write into RAM

reg [15:0] data_in = 'dZ;
wire [15:0] data_out;
reg wclke = 0, rclke = 0, we = 0, re = 0;
reg [7:0] waddr = 'dZ;
reg [7:0] raddr = 'dZ;

wire ram_ck;

assign ram_ck = clock;

DPRAM ram(
    .wclk(ram_ck), .we(we), .wclke(wclke), 
    .wdata(data_in), .rdata(data_out),
    .rclke(rclke), .re(re), .rclk(ram_ck), 
    .waddr(waddr), .raddr(raddr));

task ram_write;
    input [15:0] data;
    input [7:0] addr;

begin
    @(posedge ram_ck);
    data_in <= data;
    waddr <= addr;
    @(negedge ram_ck);
    we <= 1;
    wclke <= 1;
    @(negedge ram_ck);
    we <= 0;
    wclke <= 0;
end

endtask

task ram_read;
    input [7:0] addr;

begin
    @(posedge ram_ck);
    raddr <= addr;
    @(negedge ram_ck);
    re <= 1;
    rclke <= 1;
    @(negedge ram_ck);
    re <= 0;
    rclke <= 0;
    raddr <= 'dZ;
end

endtask

task block_write;

begin

    @(posedge ram_ck);

    // Write all channels
    // TODO : make a function for the offset calc?
    ram_write(left,     { 3'd0, frame[4:0] });
    ram_write(right,    { 3'd1, frame[4:0] });
    ram_write(16'h1234, { 3'd2, frame[4:0] });
    ram_write(16'habcd, { 3'd3, frame[4:0] });
    ram_write(16'h1000, { 3'd4, frame[4:0] });
    ram_write(16'h0100, { 3'd5, frame[4:0] });
    ram_write(16'h0010, { 3'd6, frame[4:0] });
    ram_write(16'h0001, { 3'd7, frame[4:0] });

    ram_read({ 3'd0, frame[4:0] });
    ram_read({ 3'd1, frame[4:0] });
    ram_read({ 3'd2, frame[4:0] });
    ram_read({ 3'd3, frame[4:0] });
    ram_read({ 3'd4, frame[4:0] });
    ram_read({ 3'd5, frame[4:0] });
    ram_read({ 3'd6, frame[4:0] });
    ram_read({ 3'd7, frame[4:0] });

end

endtask

always @(negedge ram_ck) begin

    if ((frame_posn == 0)) begin
        block_write();
    end

end

//  Test the TX stage

wire sdo;

I2S_TX i2s_tx (.sck(sck), .ws(ws), .frame_posn(frame_posn), .left(left), .right(right), .sd(sdo));

//  Clock the Output into an Rx to see if it works back-to-back

wire [15:0] out_left;
wire [15:0] out_right;

I2S_RX i2s_rx_out(.sck(sck), .ws(ws), .frame_posn(frame_posn), .sd(sdo), .left(out_left), .right(out_right));

endmodule

