
   /*
    *
    */

module top (
    input wire CLK, 
    output wire P1A1,
    output wire P1A2,
    input wire P1A3,
    input wire P1A4,
    input wire P1A7,
    input wire P1A8,
    output wire P1B1,
    output wire P1B2,
    output wire P1B3
    //output wire P1B4,
    //output wire LED1,
    //output wire LED2,
    //output wire LED3,
    //output wire LED4,
    //output wire LED5
);

    wire clk;
    assign clk = CLK;

    reg [5:0] reset_cnt = 0;
    wire resetn = &reset_cnt;

    always @(posedge clk) begin
        reset_cnt <= reset_cnt + ((!resetn) ? 1 : 0);
    end

    /* verilator lint_off UNUSED */
    reg iomem_valid = 0;
    wire iomem_ready;
    reg [31:0] iomem_wdata = 0;
    wire [31:0] iomem_rdata;
    reg [31:0] iomem_addr = 0;
    reg [3:0] iomem_wstrb = 0;
    wire [7:0] test;
    wire sck, ws, sd;
    wire sd_in0, sd_in1, sd_in2, sd_in3;
    /* verilator lint_on UNUSED */

    assign P1A1 = sck;
    assign P1A2 = ws;
    assign sd_in0 = P1A3;
    assign sd_in1 = P1A4;
    assign sd_in2 = P1A7;
    assign sd_in3 = P1A8;

    assign P1B1 = sck;
    assign P1B2 = ws;
    assign P1B3 = sd;

    audio_engine #(.ADDR(16'h6000)) engine(.ck(clk), .rst(resetn),
        .iomem_valid(iomem_valid),
        .iomem_ready(iomem_ready),
        .iomem_wstrb(iomem_wstrb),
        .iomem_addr(iomem_addr),
        .iomem_wdata(iomem_wdata),
        .iomem_rdata(iomem_rdata),
        .sck(sck), .ws(ws), .sd_out(sd), 
        .sd_in0(sd_in0), .sd_in1(sd_in1), .sd_in2(sd_in2), .sd_in3(sd_in3),
        .test(test)
    );


endmodule

