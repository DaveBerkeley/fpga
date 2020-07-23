
module soc (
    input wire wb_clk,
    input wire wb_rst,
    output wire timer_irq,
    // iBus
    input wire [31:0] wb_ibus_adr,
    output wire [31:0] wb_ibus_rdt,
    output wire wb_ibus_ack,
    input wire wb_ibus_cyc,
    // dBus
    input wire [31:0] wb_dbus_adr,
    input wire [31:0] wb_dbus_dat,
    input wire [3:0] wb_dbus_sel,
    input wire wb_dbus_we,
    input wire wb_dbus_cyc,
    output wire [31:0] wb_dbus_rdt,
    output wire wb_dbus_ack,

    output wire [7:0] test,
    output wire q
);

   parameter memfile = "";
   parameter memsize = 8192;
   parameter sim = 0;
   parameter with_csr = 1;

   wire [31:0] 	wb_dmem_adr;
   wire [31:0] 	wb_dmem_dat;
   wire [3:0] 	wb_dmem_sel;
   wire 	wb_dmem_we;
   wire 	wb_dmem_cyc;
   wire [31:0] 	wb_dmem_rdt;
   /* verilator lint_off UNUSED */
   wire 	wb_dmem_ack;

   wire [31:0] 	wb_mem_adr;
   /* verilator lint_on UNUSED */
   wire [31:0] 	wb_mem_dat;
   wire [3:0] 	wb_mem_sel;
   wire 	wb_mem_we;
   wire 	wb_mem_cyc;
   wire [31:0] 	wb_mem_rdt;
   wire 	wb_mem_ack;

   wire 	wb_gpio_dat;
   wire 	wb_gpio_we;
   wire 	wb_gpio_cyc;
   wire 	wb_gpio_rdt;

   wire [31:0] 	wb_timer_dat;
   wire 	wb_timer_we;
   wire 	wb_timer_cyc;
   wire [31:0] 	wb_timer_rdt;

   servant_arbiter arbiter
     (.i_wb_cpu_dbus_adr (wb_dmem_adr),
      .i_wb_cpu_dbus_dat (wb_dmem_dat),
      .i_wb_cpu_dbus_sel (wb_dmem_sel),
      .i_wb_cpu_dbus_we  (wb_dmem_we ),
      .i_wb_cpu_dbus_cyc (wb_dmem_cyc),
      .o_wb_cpu_dbus_rdt (wb_dmem_rdt),
      .o_wb_cpu_dbus_ack (wb_dmem_ack),

      .i_wb_cpu_ibus_adr (wb_ibus_adr),
      .i_wb_cpu_ibus_cyc (wb_ibus_cyc),
      .o_wb_cpu_ibus_rdt (wb_ibus_rdt),
      .o_wb_cpu_ibus_ack (wb_ibus_ack),

      .o_wb_cpu_adr (wb_mem_adr),
      .o_wb_cpu_dat (wb_mem_dat),
      .o_wb_cpu_sel (wb_mem_sel),
      .o_wb_cpu_we  (wb_mem_we ),
      .o_wb_cpu_cyc (wb_mem_cyc),
      .i_wb_cpu_rdt (wb_mem_rdt),
      .i_wb_cpu_ack (wb_mem_ack));

  /*
    wire [3:0] arb_addr;
    assign arb_addr = wb_dbus_adr[31:28];

    wire rom_en;
    wire rom_ack;
    arb #(.ADDR(4'h0), .WIDTH(4)) rom_arb
            (.wb_ck(wb_clk),
            .addr(arb_addr),
            .wb_cyc(wb_ibus_cyc),
            .wb_rst(wb_rst),
            .ack(rom_ack), 
            .en(rom_en));

    wire ram_en;
    wire ram_ack_nowt;
    arb #(.ADDR(4'h0), .WIDTH(4)) ram_arb
            (.wb_ck(wb_clk),
            .addr(arb_addr),
            .wb_cyc(wb_dbus_cyc),
            .wb_rst(wb_rst),
            .ack(ram_ack_nowt), 
            .en(ram_en));

    wire gpio_en;
    wire gpio_ack;
    arb #(.ADDR(4'h4), .WIDTH(4)) gpio_arb
            (.wb_ck(wb_clk),
            .addr(arb_addr),
            .wb_cyc(wb_dbus_cyc),
            .wb_rst(wb_rst),
            .ack(gpio_ack), 
            .en(gpio_en));

    wire timer_en;
    wire timer_ack;
    arb #(.ADDR(4'h8), .WIDTH(4)) timer_arb
            (.wb_ck(wb_clk),
            .addr(arb_addr),
            .wb_cyc(wb_dbus_cyc),
            .wb_rst(wb_rst),
            .ack(timer_ack), 
            .en(timer_en));
        */

   servant_mux #(sim) servant_mux
     (
      .i_clk (wb_clk),
      .i_rst (wb_rst),
      .i_wb_cpu_adr (wb_dbus_adr),
      .i_wb_cpu_dat (wb_dbus_dat),
      .i_wb_cpu_sel (wb_dbus_sel),
      .i_wb_cpu_we  (wb_dbus_we),
      .i_wb_cpu_cyc (wb_dbus_cyc),
      .o_wb_cpu_rdt (wb_dbus_rdt),
      .o_wb_cpu_ack (wb_dbus_ack),

      .o_wb_mem_adr (wb_dmem_adr),
      .o_wb_mem_dat (wb_dmem_dat),
      .o_wb_mem_sel (wb_dmem_sel),
      .o_wb_mem_we  (wb_dmem_we),
      .o_wb_mem_cyc (wb_dmem_cyc),
      .i_wb_mem_rdt (wb_dmem_rdt),

      .o_wb_gpio_dat (wb_gpio_dat),
      .o_wb_gpio_we  (wb_gpio_we),
      .o_wb_gpio_cyc (wb_gpio_cyc),
      .i_wb_gpio_rdt (wb_gpio_rdt),

      .o_wb_timer_dat (wb_timer_dat),
      .o_wb_timer_we  (wb_timer_we),
      .o_wb_timer_cyc (wb_timer_cyc),
      .i_wb_timer_rdt (wb_timer_rdt));

   servant_ram
     #(.memfile (memfile),
       .depth (memsize))
   ram
     (// Wishbone interface
      .i_wb_clk (wb_clk),
      .i_wb_adr (wb_mem_adr[$clog2(memsize)-1:2]),
      .i_wb_cyc (wb_mem_cyc),
      .i_wb_we  (wb_mem_we) ,
      .i_wb_sel (wb_mem_sel),
      .i_wb_dat (wb_mem_dat),
      .o_wb_rdt (wb_mem_rdt),
      .o_wb_ack (wb_mem_ack));

  assign test[0] = wb_clk;
  assign test[1] = wb_rst;
  assign test[2] = wb_dbus_cyc;
  assign test[3] = wb_dbus_we;
  assign test[4] = 0;
  assign test[5] = wb_dbus_ack;
  assign test[6] = wb_dbus_adr[30];
  assign test[7] = wb_dbus_adr[31];

   generate
      if (with_csr) begin
	 servant_timer
	   #(.WIDTH (32))
	 timer
	   (.i_clk    (wb_clk),
	    .o_irq    (timer_irq),
	    .i_wb_cyc (wb_timer_cyc),
	    .i_wb_we  (wb_timer_we) ,
	    .i_wb_dat (wb_timer_dat),
	    .o_wb_dat (wb_timer_rdt));
      end else begin
	 assign wb_timer_rdt = 32'd0;
	 assign timer_irq = 1'b0;
      end
   endgenerate

   servant_gpio gpio
     (.i_wb_clk (wb_clk),
      .i_wb_dat (wb_gpio_dat),
      .i_wb_we  (wb_gpio_we),
      .i_wb_cyc (wb_gpio_cyc),
      .o_wb_rdt (wb_gpio_rdt),
      .o_gpio   (q));

endmodule

