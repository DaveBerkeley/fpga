
   /*
    *
    */

module top (input wire CLK, output wire P1A1, output wire P1A2, output wire P1A3, output wire P1A4);

    wire ck;
    assign ck = CLK;

    reg [1:0] reset_cnt = 0;
    wire rst = & reset_cnt;

    always @(posedge ck) begin
        if (!rst)
            reset_cnt <= reset_cnt + 1;
    end

    reg        iomem_valid = 0;
    /* verilator lint_off UNUSED */
    wire        iomem_ready;
    /* verilator lint_on UNUSED */
    reg [3:0]  iomem_wstrb = 0;
    reg [31:0] iomem_addr = 0;
    reg [31:0] iomem_wdata = 0;
    /* verilator lint_off UNUSED */
    wire [31:0] iomem_rdata;
    /* verilator lint_on UNUSED */

    /* verilator lint_off UNUSED */
    wire [7:0] test;
    /* verilator lint_on UNUSED */

    audio_engine engine(.ck(ck), .rst(rst),
        .iomem_valid(iomem_valid),
        .iomem_ready(iomem_ready),
        .iomem_wstrb(iomem_wstrb),
        .iomem_addr(iomem_addr),
        .iomem_wdata(iomem_wdata),
        .iomem_rdata(iomem_rdata),
        .test(test)
    );

    assign P1A1 = ck;
    assign P1A2 = iomem_valid;
    assign P1A3 = 0;
    assign P1A4 = 0;

endmodule

