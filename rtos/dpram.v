

module dpram 
# (parameter BITS=16, SIZE=256, AWIDTH=$clog2(SIZE))
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

    always @(posedge ck) begin

        if (we) begin
            ram[waddr] <= wdata;
        end

        if (re) begin
            rdata <= ram[raddr];
        end

    end

endmodule 

//  FIN
