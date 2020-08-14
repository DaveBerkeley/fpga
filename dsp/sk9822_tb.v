

`default_nettype none
`timescale 1ns / 100ps

module tb ();

    initial begin
        $dumpfile("dsp.vcd");
        $dumpvars(0, tb);
        #500000 $finish;
    end

    reg ck = 0;

    always #42 ck <= !ck;

    wire rst;

    reset #(.LENGTH(4)) reset (.ck(ck), .rst_req(1'b0), .rst(rst));

    wire wb_clk;
    assign wb_clk = ck;
    wire wb_rst;
    assign wb_rst = rst;

    reg wb_dbus_cyc = 0;
    reg wb_dbus_we = 0;
    reg [31:0] wb_dbus_adr = 32'hZ;
    reg [31:0] wb_dbus_dat = 32'hZ;

    wire ack;
    wire led_ck;
    wire led_data;

    sk9822_peripheral
    #(.ADDR(8'hab))
    sk9822_peripheral(
        .wb_clk(wb_clk),
        .wb_rst(wb_rst),
        .wb_dbus_cyc(wb_dbus_cyc),
        .wb_dbus_we(wb_dbus_we),
        .wb_dbus_adr(wb_dbus_adr),
        .wb_dbus_dat(wb_dbus_dat),
        .ack(ack),
        .led_ck(led_ck),
        .led_data(led_data)
    );

    task write(input [31:0] addr, input [31:0] data);

        begin
            wb_dbus_cyc <= 1;
            wb_dbus_adr <= addr;
            wb_dbus_dat <= data;
            wb_dbus_we <= 1;
        end

    endtask

    localparam ADDR = 32'hab00_0000;

    // respond to ACK
    always @(posedge wb_clk) begin
        if (ack) begin
            wb_dbus_cyc <= 0;
            wb_dbus_adr <= 32'hZ;
            wb_dbus_dat <= 32'hZ;
            wb_dbus_we <= 0;
        end
    end

    integer i;

    initial begin
        $display("start");

        wait(!wb_rst);
        @(posedge wb_clk);
        @(posedge wb_clk);
        @(posedge wb_clk);
        @(posedge wb_clk);
        @(posedge wb_clk);

        for (i = 0; i < 16; i = i + 1) begin
            write(ADDR+(i*4), i + (i << 8) + (i << 16));
            wait(ack);
            wait(!ack);
            @(posedge wb_clk);
        end

        $display("done");
        //$finish;
    end

endmodule


