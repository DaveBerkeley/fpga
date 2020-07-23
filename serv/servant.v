`default_nettype none

   /*
    *
    */

module arb
    #(parameter ADDR=0, WIDTH=8)
    (input wire wb_ck, 
    input wire [(WIDTH-1):0] addr, 
    input wire wb_cyc, 
    input wire wb_rst,
    output reg ack, output wire en);

    wire match;
    assign match = addr == ADDR;
    assign en = match & wb_cyc;

    always @(posedge wb_ck) begin
        ack <= 0;
        if (wb_cyc && match)
            ack <= 1;
        if (wb_rst)
            ack <= 0;
    end

endmodule

   /*
    *
    */

module servant
(
 input wire  wb_clk,
 input wire  wb_rst,
 output wire q,
 output wire [7:0] test
);

   parameter memfile = "";
   parameter memsize = 8192;
   parameter sim = 0;
   parameter with_csr = 1;

   wire 	timer_irq;

   wire [31:0] 	wb_ibus_adr;
   wire 	wb_ibus_cyc;
   wire [31:0] 	wb_ibus_rdt;
   wire 	wb_ibus_ack;

   wire [31:0] 	wb_dbus_adr;
   wire [31:0] 	wb_dbus_dat;
   wire [3:0] 	wb_dbus_sel;
   wire 	wb_dbus_we;
   wire 	wb_dbus_cyc;
   wire [31:0] 	wb_dbus_rdt;
   wire 	wb_dbus_ack;

   wire [31:0] 	wb_dmem_adr;
   wire [31:0] 	wb_dmem_dat;
   wire [3:0] 	wb_dmem_sel;
   wire 	wb_dmem_we;
   wire 	wb_dmem_cyc;
   wire [31:0] 	wb_dmem_rdt;
   wire 	wb_dmem_ack;

   wire [31:0] 	wb_mem_adr;
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

    soc #(.memfile(memfile), .memsize(memsize))
    io (.wb_clk(wb_clk),
        .wb_rst(wb_rst),
        .timer_irq(timer_irq),
        // iBus
        .wb_ibus_adr(wb_ibus_adr),
        .wb_ibus_rdt(wb_ibus_rdt),
        .wb_ibus_ack(wb_ibus_ack),
        .wb_ibus_cyc(wb_ibus_cyc),
        // dBus
        .wb_dbus_adr(wb_dbus_adr),
        .wb_dbus_dat(wb_dbus_dat),
        .wb_dbus_sel(wb_dbus_sel),
        .wb_dbus_we(wb_dbus_we),
        .wb_dbus_cyc(wb_dbus_cyc),
        .wb_dbus_rdt(wb_dbus_rdt),
        .wb_dbus_ack(wb_dbus_ack),
    
        .test(test),
        .q(q)
    );

    serv_rf_top
     #(.RESET_PC (32'h0000_0000),
       .WITH_CSR (with_csr))
   cpu
     (
      .clk      (wb_clk),
      .i_rst    (wb_rst),
      .i_timer_irq  (timer_irq),

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
