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
    output wire ack, 
    output wire en);

    wire match;
    assign match = addr == ADDR;
    assign en = match & wb_cyc;

    reg [1:0] state = 0;

    always @(posedge wb_ck) begin

        if (wb_rst || (!match) || !wb_cyc)
            state <= 0;
        else begin
            case (state)
                0 : state <= 1;
                1 : state <= 2;
                2 : state <= 3;
                3 : state <= 0;
            endcase
        end

    end

    assign ack = state == 1;

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
   wire [31:0] 	soc_rdt;
   wire 	wb_dbus_ack;

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
        .wb_dbus_rdt(soc_rdt),
        .wb_dbus_ack(wb_dbus_ack)
    );

    // GPIO for TX line

    wire gpio_en;
    wire gpio_ack;
    arb #(.ADDR(2'b01), .WIDTH(2))
        gpio_arb 
        (.wb_ck(wb_clk),
        .addr(wb_dbus_adr[31:30]),
        .wb_cyc(wb_dbus_cyc),
        .wb_rst(wb_rst),
        .ack(gpio_ack),
        .en(gpio_en));

    reg [7:0] gpio = 0;

    always @(posedge wb_clk) begin
        if (gpio_en) begin
            gpio <= wb_dbus_dat[7:0];
        end
    end

    wire [31:0] wb_dbus_rdt;
    assign wb_dbus_rdt = gpio_ack ? { 24'h0, gpio } : soc_rdt;

    assign q = gpio[0];

  assign test[0] = wb_clk;
  assign test[1] = wb_rst;
  assign test[2] = wb_dbus_cyc;
  assign test[3] = wb_dbus_we;
  assign test[4] = 0;
  assign test[5] = wb_dbus_ack;
  assign test[6] = wb_dbus_adr[30];
  assign test[7] = wb_dbus_adr[31];

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
