

module dpram 
# (parameter BITS=16, SIZE=256, AWIDTH=$clog2(SIZE), FILE="")
(   
    input wire ck,
    input wire we,
    input wire [AWIDTH-1:0] waddr,
    input wire [BITS-1:0] wdata,
 
    input wire re,
    input wire [AWIDTH-1:0] raddr,
    output reg [BITS-1:0] rdata
);

    reg [BITS-1:0] ram [0:SIZE-1];

`ifdef SIMULATION
	//$display("Preloading %m from %s", FILE);    
    initial begin
        $readmemh(FILE, ram);
    end
`endif

    always @(posedge ck) begin
        if (we)
            ram[waddr] <= wdata;
        if (re)
            rdata <= ram[raddr];
    end

endmodule 

//  FIN
