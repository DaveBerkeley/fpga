
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
    output reg [31:0] rdata
);

    parameter SIMULATION = 0;
    parameter WORDS = 256;

    generate 

        if (SIMULATION) begin

            reg [31:0] mem [0:WORDS-1];

            always @(posedge ck) begin
                rdata <= mem[addr];
                if (we[0]) mem[addr][ 7: 0] <= wdata[ 7: 0];
                if (we[1]) mem[addr][15: 8] <= wdata[15: 8];
                if (we[2]) mem[addr][23:16] <= wdata[23:16];
                if (we[3]) mem[addr][31:24] <= wdata[31:24];
            end

        end else begin

            wire [3:0] w_enable;

            assign w_enable = (cyc & we) ? sel : 4'b0;

            ice40up5k_spram #(.WORDS(32768)) // (128 kB)
                ram (
                .clk(ck),
                .wen(w_enable),
                .addr(addr[21:0]),
                .wdata(wdata),
                .rdata(rdata)
                );
        end

    endgenerate

endmodule 


