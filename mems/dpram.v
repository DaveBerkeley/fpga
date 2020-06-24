

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

