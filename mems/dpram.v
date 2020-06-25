

module DPRAM (   
    input wire wclk,
    input wire we,
    input wire wclke,
    input wire [7:0] waddr,
    input wire [15:0] wdata,
    
    input wire rclk,
    input wire re,
    input wire rclke,
    input wire [7:0] raddr,
    output reg [15:0] rdata
);

reg [15:0] ram[0:255];

always@(posedge wclk)
begin

    if(wclke & we)
        ram[waddr] <= wdata;

end

always@(posedge rclk)
begin

    if (rclke & re)
        rdata <= ram[raddr];

end

endmodule 

   /*
    *
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
    begin
        // End the write cycle
        we <= 0;
    end
    else if (start)
    begin
        // Start the write cycle
        odata <= data;
        oaddr <= addr;
        we <= 1;
    end

end

endmodule


