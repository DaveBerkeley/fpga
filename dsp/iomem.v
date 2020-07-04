
   /*
    *   Handle iomem interface
    *
    *   Interface to the Risc-V bus
    */

module iomem (
    input wire ck,
    input wire rst,
    input wire iomem_valid,
    input wire [3:0] iomem_wstrb,
    /* verilator lint_off UNUSED */
    input wire [31:0] iomem_addr,
    /* verilator lint_on UNUSED */

    output reg ready,
    output wire we,
    output wire re
);

    parameter ADDR = 16'h6000;

    initial ready = 0;

    wire enable;

    assign enable = rst && iomem_valid && (!ready) && (iomem_addr[31:16] == ADDR);

    wire write;
    assign write = | iomem_wstrb;
    assign we = enable & write;
    assign re = enable & !write;

    always @(negedge ck) begin
        
        ready <= (rst & enable) ? 1 : 0;

    end

endmodule
    
//  FIN
