
`default_nettype none

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

   /*
    *
    */

module servant
(
    input wire  wb_clk,
    input wire  wb_rst,

    // wishbone data bus
    output [31:0] wb_dbus_adr,
    output [31:0] wb_dbus_dat,
    output [3:0] wb_dbus_sel,
    output wb_dbus_we,
    output wb_dbus_cyc,
    input [31:0] wb_xbus_rdt,
    input wb_xbus_ack,
    //
    output wire [31:0] wb_ibus_adr,
    output wire wb_ibus_cyc,
    input wire [31:0] wb_ibus_rdt,
    input wire wb_ibus_ack
);

    parameter memfile = "";
    // Size of the ROM/RAM storage in bytes
    parameter memsize = 8 * 1024;
    //parameter sim = 0;
    parameter with_csr = 1;

    wire ram_ack;
    wire ram_cyc;

    arb #(.ADDR(0), .WIDTH(2))
        arb_ram (
            .wb_ck(wb_clk),
            .addr(wb_dbus_adr[31:30]),
            .wb_cyc(wb_dbus_cyc),
            .wb_rst(wb_rst),
            .ack(ram_ack),
            .cyc(ram_cyc));
  
    //  Dbus RAM

    localparam RAM_ADDR_W = $clog2(memsize/4);

    wire [(RAM_ADDR_W-1):0] ram_adr;
    assign ram_adr = wb_dbus_adr[(RAM_ADDR_W+2-1):2];

    wire [31:0] ram_rdt;

    sp_ram #(.SIZE(memsize/4))
    ram (
        .ck(wb_clk),
        .addr(ram_adr),
        .cyc(ram_cyc),
        .we(wb_dbus_we),
        .sel(wb_dbus_sel),
        .wdata(wb_dbus_dat),
        .rdata(ram_rdt)
    );

    // Ibus

   // SoC signals have priority

    wire [31:0] wb_dbus_rdt;
    wire wb_dbus_ack;
  
    assign wb_dbus_rdt = wb_xbus_ack ? wb_xbus_rdt : ram_rdt;
    assign wb_dbus_ack = wb_xbus_ack | ram_ack;

   serv_rf_top
     #(.RESET_PC (32'h0000_0000),
       .WITH_CSR (with_csr))
   cpu
     (
      .clk      (wb_clk),
      .i_rst    (wb_rst),
      .i_timer_irq  (1'b0),
`ifdef RISCV_FORMAL
      .rvfi_valid     (),
      .rvfi_order     (),
      .rvfi_insn      (),
      .rvfi_trap      (),
      .rvfi_halt      (),
      .rvfi_intr      (),
      .rvfi_mode      (),
      .rvfi_ixl       (),
      .rvfi_rs1_addr  (),
      .rvfi_rs2_addr  (),
      .rvfi_rs1_rdata (),
      .rvfi_rs2_rdata (),
      .rvfi_rd_addr   (),
      .rvfi_rd_wdata  (),
      .rvfi_pc_rdata  (),
      .rvfi_pc_wdata  (),
      .rvfi_mem_addr  (),
      .rvfi_mem_rmask (),
      .rvfi_mem_wmask (),
      .rvfi_mem_rdata (),
      .rvfi_mem_wdata (),
`endif

      .o_ibus_adr   (wb_ibus_adr),
      .o_ibus_cyc   (wb_ibus_cyc),
      .i_ibus_rdt   (wb_ibus_rdt),
      .i_ibus_ack   (wb_ibus_ack),

      .o_dbus_adr   (wb_dbus_adr),
      .o_dbus_dat   (wb_dbus_dat),
      .o_dbus_sel   (wb_dbus_sel),
      .o_dbus_we    (wb_dbus_we),
      .o_dbus_cyc   (wb_dbus_cyc),
      .i_dbus_rdt   (wb_dbus_rdt),
      .i_dbus_ack   (wb_dbus_ack));

endmodule
