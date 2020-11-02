
`default_nettype none

module sp_ram 
(   
    input wire ck,
    input wire cyc,
    input wire we,
    input wire [3:0] sel,
    /* verilator lint_off UNUSED */
    input wire [31:0] addr,
    /* verilator lint_on UNUSED */
    input wire [31:0] wdata,
    output wire [31:0] rdata
);

    parameter WORDS = 8 * 1024; // 32768;

    reg [31:0] mem [0:(WORDS-1)];

    always @(posedge ck) begin
        if (we) begin
            if (sel[0]) mem[addr][ 7: 0] <= wdata[ 7: 0];
            if (sel[1]) mem[addr][15: 8] <= wdata[15: 8];
            if (sel[2]) mem[addr][23:16] <= wdata[23:16];
            if (sel[3]) mem[addr][31:24] <= wdata[31:24];
        end
        rdata <= mem[addr];
    end

endmodule

//  FIN
