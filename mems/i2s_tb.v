
`default_nettype none
`timescale 1ns / 100ps

   /*
    *
    */

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

I2S_RX i2s(.sck(sck), .frame_posn(frame_posn), .sd(sdi), .left(left), .right(right));

//  Write into RAM

wire [15:0] data_in;
wire [15:0] data_out;
wire we;
reg re = 0;
wire [7:0] waddr;
reg [7:0] raddr = 'dZ;

wire ram_ck;

assign ram_ck = clock;

DPRAM ram(
    .wclk(ram_ck), .wclke(we), .we(we), .waddr(waddr), .wdata(data_in), 
    .rclk(ram_ck), .rclke(re), .re(re), .raddr(raddr), .rdata(data_out)
);

reg write = 0;
reg [15:0] wr_data;
reg [7:0] wr_addr;
wire wr_busy;

assign wr_busy = we;

writer writer(.ck(ram_ck), .start(write), .data(wr_data), .addr(wr_addr), 
    .odata(data_in), .oaddr(waddr), .we(we));

   /*
    *   Write the signals to RAM
    */

reg [2:0] channel = 0;

task write_data(input [2:0] offset, input [15:0] data);

    begin
        write <= 1;
        wr_data <= data;
        wr_addr <= { offset, frame[4:0] };
        channel <= channel + 1;
    end

endtask

always @(posedge ram_ck) begin

    if (write)
        write <= 0;

    if (frame_posn == 63)
        channel <= 0;

    if ((frame_posn == 0) && (channel == 0))
    begin
        write_data(channel, left);
    end

    if (!wr_busy)
    begin
        case (channel)
            1 : write_data(channel, right);
            2 : write_data(channel, 16'h1234);
            3 : write_data(channel, 16'habcd);
            4 : write_data(channel, 16'h1000);
            5 : write_data(channel, 16'h0100);
            6 : write_data(channel, 16'h0010);
            7 : write_data(channel, 16'h0001);
        endcase
    end
 

end

//  Test the TX stage

wire sdo;

I2S_TX i2s_tx (.sck(sck), .frame_posn(frame_posn), .left(left), .right(right), .sd(sdo));

//  Clock the Output into an Rx to see if it works back-to-back

wire [15:0] out_left;
wire [15:0] out_right;

I2S_RX i2s_rx_out(.sck(sck), .frame_posn(frame_posn), .sd(sdo), .left(out_left), .right(out_right));

endmodule

