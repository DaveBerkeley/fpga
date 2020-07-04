
`default_nettype none
`timescale 1ns / 100ps

module top ();

    /* verilator lint_off COMBDLY */
    /* verilator lint_off INITIALDLY */

    // 12MHz clock
    reg ck = 0;
    always #42 ck <= !ck;

    /* verilator lint_off UNUSED */
    reg rst = 0;
    reg iomem_valid = 0;
    reg [3:0] iomem_wstrb = 0;
    reg [31:0] iomem_addr = 0;
    reg [31:0] iomem_data = 32'hX;

    wire ready;
    wire we;
    wire re;
    /* verilator lint_on UNUSED */

    iomem #(.ADDR(16'h6000)) io (.ck(ck), .rst(rst),
        .iomem_valid(iomem_valid), .iomem_wstrb(iomem_wstrb), .iomem_addr(iomem_addr),
        .ready(ready), .we(we), .re(re));

    task write(input [31:0] addr);

        begin
            @(negedge ck);
            iomem_valid <= 1;
            iomem_wstrb <= 4'hf;
            iomem_addr <= addr;
            @(negedge ck);
            @(negedge ck);
        end

    endtask

    task read(input [31:0] addr, input [31:0] data);

        begin
            @(negedge ck);
            iomem_valid <= 1;
            iomem_wstrb <= 4'h0;
            iomem_addr <= addr;
            @(posedge ck);
            iomem_data <= data;
            @(negedge ck);
            @(negedge ck);
        end

    endtask

    always @(negedge ck) begin
        if (ready) begin
            iomem_valid <= 0;
            iomem_wstrb <= 4'h0;
            iomem_addr <= 0;
        end
        if (ready)
            iomem_data <= 32'hX;
    end

    initial begin
`ifdef SIMULATION
        $dumpfile("iomem.vcd");
        $dumpvars(0, top);
`endif

        #1000 
        rst <= 1;
        #500

        write(32'h60000000);
        write(32'h60000004);
        read(32'h60000004, 32'h12345678);

        #5000000 $finish;
    end

endmodule

