
module sp_ram 
    # (parameter SIZE=256, AWIDTH=$clog2(SIZE))
(   
    input wire ck,
    input wire cyc,
    input wire we,
    input wire [3:0] sel,
    input wire [AWIDTH-1:0] addr,
    input wire [31:0] wdata,
 
    output reg [31:0] rdata
);

    reg [31:0] sram [0:SIZE-1];

    always @(posedge ck) begin
        if (cyc) begin
            if (we) begin
                if (sel[0])
                    sram[addr][7:0] <= wdata[7:0];
                if (sel[1])
                    sram[addr][15:8] <= wdata[15:8];
                if (sel[2])
                    sram[addr][23:16] <= wdata[23:16];
                if (sel[3])
                    sram[addr][31:24] <= wdata[31:24];
            end

            rdata <= sram[addr];
        end
    end

endmodule 


