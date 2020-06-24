
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
wire [3:0] prescale;
I2S_CLOCK i2s_ck(.ck(clock), .sck(sck), .ws(ws), .frame_posn(frame_posn), .prescale(prescale));

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

//  Write into RAM

reg [15:0] data_in = 'dZ;
wire [15:0] data_out;
reg wclke = 0, rclke, we = 0, re;
reg [7:0] waddr = 'dZ;
wire [7:0] raddr;

wire ram_ck;

assign ram_ck = prescale[0];

DPRAM ram(.wclk(ram_ck), .rclk(clock), .wclke(wclke), .rclke(rclke), .we(we), .re(re),
    .wdata(data_in), .rdata(data_out),
    .waddr(waddr), .raddr(raddr));

task ram_write;
    input [15:0] datai;
    input [7:0] addri;

begin
    @(posedge ram_ck);
    data_in <= datai;
    waddr <= addri;
    @(negedge ram_ck);
    we <= 1;
    wclke <= 1;
    @(negedge ram_ck);
    data_in <= 'dZ;
    waddr <= 'dZ;
    we <= 0;
    wclke <= 0;
end

endtask

reg [3:0] mic_idx;

initial mic_idx = 0;

wire [7:0] mic_0_addr;
wire [7:0] mic_1_addr;
assign mic_0_addr = { 4'd0, mic_idx };
assign mic_1_addr = { 4'd1, mic_idx };

always @(negedge clock) begin

    if ((frame_posn == 32) && (prescale == 0)) begin
        mic_idx <= mic_idx + 1;
    end

    if ((frame_posn == 32) && (prescale == 0)) begin
        ram_write(left, mic_0_addr);
    end

    if ((frame_posn == 33) && (prescale == 0)) begin
        ram_write(right, mic_1_addr);
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

