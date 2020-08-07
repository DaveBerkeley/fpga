
module dma
# (parameter ADDR=0, WIDTH=8)
(
    // CPU bus interface
    input wire wb_clk,
    input wire wb_rst,
    input wire wb_dbus_cyc,
    input wire wb_dbus_we,
    /* verilator lint_off UNUSED */
    input wire [31:0] wb_dbus_adr,
    input wire [31:0] wb_dbus_dat,
    /* verilator lint_on UNUSED */
    output wire [31:0] dbus_rdt,
    output wire dbus_ack,

    // Xfer 
    input wire xfer_block,
    output reg block_done,
    output reg xfer_done,

    // Src data
    output reg [15:0] xfer_adr,
    output wire xfer_re,
    input wire [15:0] xfer_dat,

    // DMA interface
    output reg dma_cyc,
    output reg dma_we,
    output reg [3:0] dma_sel,
    output reg [31:0] dma_adr,
    output wire [31:0] dma_dat,
    input wire dma_ack,
    /* verilator lint_off UNUSED */
    input wire [31:0] dma_rdt
    /* verilator lint_on UNUSED */
);

    initial begin
        dma_cyc = 0;
        dma_we = 0;
        dma_sel = 0;
        dma_adr = 0;

        block_done = 0;
        xfer_done = 0;
        xfer_adr = 0;
    end

    wire cs_ack, cs_cyc;

    wire [7:0] cs_adr = wb_dbus_adr[31:24];

    chip_select #(.ADDR(ADDR), .WIDTH(WIDTH))
    cs_dma(
        .wb_ck(wb_clk),
        .addr(cs_adr),
        .wb_cyc(wb_dbus_cyc),
        .wb_rst(wb_rst),
        .ack(cs_ack),
        .cyc(cs_cyc)
    );

    reg [23:0] reg_addr = 0;
    reg [15:0] reg_step = 0;
    reg [15:0] reg_cycles = 0;
    reg [15:0] reg_blocks = 0;
    reg reg_start_req = 0;

    reg [15:0] block = 0;
    reg [23:0] addr = 0;

    wire [2:0] io_addr;
    assign io_addr = wb_dbus_adr[4:2];

    // Write to the control registers

    wire writing;
    assign writing = cs_cyc & wb_dbus_we;

    always @(posedge wb_clk) begin

        if (writing) begin

            case (io_addr)
                0   :   reg_addr   <= wb_dbus_dat[23:0];
                1   :   reg_step   <= wb_dbus_dat[15:0];
                2   :   reg_cycles <= wb_dbus_dat[15:0];
                3   :   reg_blocks <= wb_dbus_dat[15:0];
                4   :   reg_start_req <= 1;
                5   :   reg_start_req <= 0;
            endcase

        end

    end

    wire [31:0] status;
    assign status = { 30'h0, block_done, xfer_done };

    function [31:0] rdt(input [2:0] rd_addr);

        begin

            case (rd_addr)
                0   :   rdt = { 8'h0, reg_addr };
                1   :   rdt = { 16'h0, reg_step };
                2   :   rdt = { 16'h0, reg_cycles };
                3   :   rdt = { 16'h0, reg_blocks };
                6   :   rdt = status;
            endcase

        end

    endfunction

    wire reading;
    assign reading = cs_ack & !wb_dbus_we;
    assign dbus_rdt = reading ? rdt(io_addr) : 0;

    assign dbus_ack = cs_ack;

    reg block_en = 0;

    reg running = 0;
    reg [23:0] run_addr = 0;
    reg [15:0] run_cycles = 0;

    always @(posedge wb_clk) begin

        if (reg_start_req & !running) begin
            // sequence start
            run_addr <= reg_addr;
            run_cycles <= reg_cycles;
            running <= 1;
            block_done <= 0;
            xfer_done <= 0;
            running <= 1;
        end

        if (!reg_start_req) begin
            block_done <= 0;
            xfer_done <= 0;
            running <= 0;
        end

        if (reg_start_req & xfer_block) begin
            // block start
            block_en <= 1;
            addr <= run_addr;
            block <= reg_blocks;
            block_done <= 0;
            xfer_adr <= 0;
        end

        if (block_en & !dma_cyc) begin

            dma_cyc <= 1;
            dma_we <= 1;
            case (addr[1])
                0 : begin
                    dma_sel <= 4'b0011;
                end
                1 : begin
                    dma_sel <= 4'b1100;
                end
            endcase
            dma_adr <= { 8'h0, addr };
 
        end

        if (dma_ack) begin

            dma_cyc <= 0;
            dma_we <= 0;
            dma_sel <= 4'b0000;
            dma_adr <= 0;

            addr <= addr + { 8'h0, reg_step };
            block <= block - 1;
            xfer_adr <= xfer_adr + 1;

        end

        if (block_en & (block == 1) & dma_ack) begin
            // final xfer of block
            block_en <= 0;
            run_cycles <= run_cycles - 1;
            run_addr <= run_addr + 2;
        end

        if (running & (block == 0) & !(block_en | xfer_block)) begin
            // end of block
            block_done <= 1;

            if (run_cycles == 0) begin
                // all blocks completed
                xfer_done <= 1;
            end
        end

    end

    wire [31:0] data_out;

    assign data_out = addr[1] ? { xfer_dat, 16'b0 } : { 16'b0, xfer_dat }; 

    assign dma_dat = dma_ack ? data_out : 0;
    assign xfer_re = block_en & dma_ack;

endmodule
