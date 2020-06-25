

module DPRAM (   
    input wire clk,
    input wire we,
    input wire [7:0] waddr,
    input wire [15:0] wdata,
    
    input wire re,
    input wire [7:0] raddr,
    output reg [15:0] rdata
);

reg [15:0] ram[0:255];

always@(posedge clk)
begin

    if(we)
        ram[waddr] <= wdata;

    if (re)
        rdata <= ram[raddr];

end

endmodule 

//  FIN
