
module uart_tx(
    input wire ck,
    input wire baud_ck,
    input wire [7:0] in,
    input wire we,
    output reg ready,
    output reg tx);

    reg [9:0] shift = 10'h3ff;
    reg [3:0] count = 0;

    initial ready = 1;
    initial tx = 1;

    always @(posedge ck) begin

        if (baud_ck) begin
            shift <= { 1'b1, shift[9:1] };
            if (count != 0) begin
                count <= count - 1;
            end

            ready <= count == 0;
            tx <= shift[0];
        end

        if (we & ready) begin
            shift <= { 1'b1, in, 1'b0 };
            count <= 9;
            ready <= 0;
        end

    end

endmodule

   /*
    *
    */

module uart_baud
    #(parameter DIVIDE=16)
    (input wire ck, 
    output reg baud_ck
);

    localparam WIDTH = $clog2(DIVIDE);
    reg [(WIDTH-1):0] baud = 0;

    initial baud_ck = 0;

    always @(posedge ck) begin
        /* verilator lint_off WIDTH */
        if (baud == (DIVIDE - 1)) begin
            baud <= 0;
            baud_ck <= 1;
        end else begin
            baud <= baud + 1;
            baud_ck <= 0;
        end
        /* verilator lint_on WIDTH */
    end

endmodule

   /*
    *
    */

module uart
    #(parameter ADDR=0, AWIDTH=8)
    (
    // cpu bus
    input wire wb_clk,
    input wire wb_rst,
    /* verilator lint_off UNUSED */
    input [31:0] wb_dbus_adr,
    input [31:0] wb_dbus_dat,
    input [3:0] wb_dbus_sel,
    /* verilator lint_on UNUSED */
    input wb_dbus_we,
    input wb_dbus_cyc,
    output wire [31:0] rdt,
    output wire ack,
    // IO
    input wire baud_en,
    output wire tx
);

    wire cyc;
    wire uart_ready;

    arb #(.ADDR(ADDR), .WIDTH(AWIDTH))
        arb_uart (
        .wb_ck(wb_clk), 
        .addr(wb_dbus_adr[31:31-7]), 
        .wb_cyc(wb_dbus_cyc), 
        .wb_rst(wb_rst),
        .ack(ack), 
        .cyc(cyc)
    );    

    uart_tx uart(
        .ck(wb_clk),
        .baud_ck(baud_en),
        .in(wb_dbus_dat[7:0]),
        .we(cyc & wb_dbus_we),
        .ready(uart_ready),
        .tx(tx));

    assign rdt = cyc ? { 31'h0, uart_ready } : 0;

endmodule


