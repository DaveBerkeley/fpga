`default_nettype none
module servant
(
 input wire  wb_clk,
 input wire  wb_rst,

   output [31:0] 	wb_dbus_adr,
   output [31:0] 	wb_dbus_dat,
   output [3:0] 	wb_dbus_sel,
   output 	wb_dbus_we,
   output 	wb_dbus_cyc,
   input [31:0] 	wb_xbus_rdt,
   input 	wb_xbus_ack
);

   parameter memfile = "";
   parameter memsize = 8192;
   parameter sim = 0;
   parameter with_csr = 1;

   /* verilator lint_off UNUSED */
   wire [31:0] 	wb_ibus_adr;
   /* verilator lint_on UNUSED */
   wire 	wb_ibus_cyc;
   wire [31:0] 	wb_ibus_rdt;
   wire 	wb_ibus_ack;

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
  
    wire rom_ack;
    wire rom_cyc;

    arb #(.ADDR(0), .WIDTH(2))
        arb_rom (
            .wb_ck(wb_clk),
            .addr(wb_ibus_adr[31:30]),
            .wb_cyc(wb_ibus_cyc),
            .wb_rst(wb_rst),
            .ack(rom_ack),
            .cyc(rom_cyc));

    localparam ADDR_W = $clog2(memsize/4);
    wire [(ADDR_W-1):0] ram_adr;
    wire [(ADDR_W-1):0] rom_adr;

    assign ram_adr = wb_dbus_adr[(ADDR_W+2-1):2];
    assign rom_adr = wb_ibus_adr[(ADDR_W+2-1):2];

    wire [31:0] ram_rdt;
    /* verilator lint_off UNUSED */
    wire nowt;
    /* verilator lint_on UNUSED */

   servant_ram
     #(.depth (memsize))
   ram
     (// Wishbone interface
      .i_wb_clk (wb_clk),
      .i_wb_adr (ram_adr),
      .i_wb_cyc (ram_cyc),
      .i_wb_we  (wb_dbus_we) ,
      .i_wb_sel (wb_dbus_sel),
      .i_wb_dat (wb_dbus_dat),
      .o_wb_rdt (ram_rdt),
      .o_wb_ack (nowt));

    wire [31:0] rom_rdt;
    /* verilator lint_off UNUSED */
    wire nowt2;
    /* verilator lint_on UNUSED */

   servant_ram
     #(.memfile (memfile),
       .depth (memsize))
   rom
     (// Wishbone interface
      .i_wb_clk (wb_clk),
      .i_wb_adr (rom_adr),
      .i_wb_cyc (rom_cyc),
      .i_wb_we  (1'b0),
      .i_wb_sel (4'b0),
      .i_wb_dat (32'h0),
      .o_wb_rdt (rom_rdt),
      .o_wb_ack (nowt2));

   // SoC signals have priority

    wire [31:0] wb_dbus_rdt;
    wire wb_dbus_ack;
  
    assign wb_dbus_rdt = wb_xbus_ack ? wb_xbus_rdt : ram_rdt;
    assign wb_dbus_ack = wb_xbus_ack | ram_ack;
    assign wb_ibus_rdt = rom_rdt;
    assign wb_ibus_ack = rom_ack;

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
