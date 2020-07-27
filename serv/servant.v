
`default_nettype none

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

    parameter with_csr = 1;

    wire ram_ack;
    wire ram_cyc;

    chip_select #(.ADDR(0), .WIDTH(2))
        cs_ram (
            .wb_ck(wb_clk),
            .addr(wb_dbus_adr[31:30]),
            .wb_cyc(wb_dbus_cyc),
            .wb_rst(wb_rst),
            .ack(ram_ack),
            .cyc(ram_cyc));
  
    //  Dbus RAM

    wire [31:0] ram_rdt;

    sp_ram ram (
        .ck(wb_clk),
        .addr(wb_dbus_adr),
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
