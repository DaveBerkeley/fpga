
   /*
    *   Handle iomem interface
    *
    *   Interface to the Risc-V bus
    */

module iomem
    #(parameter ADDR=16'h0300)
    (input wire ck,
    input wire rst,
    input wire valid,
    input wire [3:0] wstrb,
    /* verilator lint_off UNUSED */
    input wire [31:0] addr,
    /* verilator lint_on UNUSED */

    output reg ready,
    output wire we,
    output wire re
);

    initial ready = 0;

    wire enable;
    assign enable = valid && !ready && (addr[31:16] == ADDR);

    wire write;
    assign write = | wstrb;
    assign we = enable && write; 
    assign re = enable && !write; 

    always @(posedge ck) begin
        if (rst) begin
            if (ready)
                ready <= 0;
            if (enable) begin
                ready <= 1;
            end
        end
    end

endmodule

//  FIN
