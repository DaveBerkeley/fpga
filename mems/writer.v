
   /*
    *   State machine to write a word to RAM
    */

module writer(
    input wire ck,
    input wire start,
    input wire [15:0] data,
    input wire [7:0] addr,
    output reg [15:0] odata,
    output reg [7:0] oaddr,
    output reg we
);

initial we = 0;

always @(negedge ck) begin

    if (we)
        we <= 0; // End the write cycle    else if (start)
    else begin
        if (start) begin
            // Start the write cycle
            odata <= data;
            oaddr <= addr;
            we <= 1;
        end
    end

end

endmodule


   /*
    *   Write a block of channels to the RAM
    */

module ram_writer(
    input wire ck, 
    input wire [5:0] frame_posn,
    input wire [4:0] frame,
    input wire [15:0] d0,
    input wire [15:0] d1,
    input wire [15:0] d2,
    input wire [15:0] d3,
    input wire [15:0] d4,
    input wire [15:0] d5,
    input wire [15:0] d6,
    input wire [15:0] d7,
    output reg [7:0] wr_addr,
    output reg [15:0] wr_data,
    output reg write
);

initial write = 0;
reg [2:0] channel = 0;

task write_data(input [2:0] offset, input [15:0] data);

    begin
        write <= 1;
        wr_data <= data;
        wr_addr <= { offset, frame[4:0] };
        channel <= channel + 1;
    end

endtask

always @(posedge ck) begin

    if (write)
        write <= 0;

    if (frame_posn == 63)
        channel <= 0;

    if (!write) begin
        case (channel)
            0 : if (frame_posn == 0)
                    write_data(channel, d0);
            1 : write_data(channel, d1);
            2 : write_data(channel, d2);
            3 : write_data(channel, d3);
            4 : write_data(channel, d4);
            5 : write_data(channel, d5);
            6 : write_data(channel, d6);
            7 : write_data(channel, d7);
        endcase
    end

end

endmodule

   /*
    *
    */

module save_signals(
    input wire ck,
    input wire [5:0] frame_posn,
    input wire [4:0] frame,
    input wire [15:0] d0,
    input wire [15:0] d1,
    input wire [15:0] d2,
    input wire [15:0] d3,
    input wire [15:0] d4,
    input wire [15:0] d5,
    input wire [15:0] d6,
    input wire [15:0] d7
);

//  Write into RAM

wire [15:0] wdata;
/* verilator lint_off UNUSED */
wire [15:0] rdata;
/* verilator lint_on UNUSED */
wire we;
reg re = 0;
wire [7:0] waddr;
wire [7:0] raddr;

assign raddr = 0;

DPRAM ram_0(.clk(ck), .we(we), .waddr(waddr), .wdata(wdata), .re(re), .raddr(raddr), .rdata(rdata));

wire start;
wire [15:0] wr_data;
wire [7:0] wr_addr;

writer writer(.ck(ck), .start(start), .data(wr_data), .addr(wr_addr), .odata(wdata), .oaddr(waddr), .we(we));

   /*
    *   Write the signals to RAM
    */

ram_writer ww(.ck(ck), 
    .frame_posn(frame_posn),
    .frame(frame[4:0]),
    .d0(d0),
    .d1(d1),
    .d2(d2),
    .d3(d3),
    .d4(d4),
    .d5(d5),
    .d6(d6),
    .d7(d7),
    .wr_addr(wr_addr),
    .wr_data(wr_data),
    .write(start));

endmodule
