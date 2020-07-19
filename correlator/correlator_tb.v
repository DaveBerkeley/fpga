
`default_nettype none
`timescale 1ns / 100ps

module tb ();

    reg ck = 0;

    always #42 ck <= !ck;

    initial begin
        $dumpfile("correlator.vcd");
        $dumpvars(0, tb);
        #500000 $finish;
    end

    reg [1:0] reset = 0;

    always @(posedge ck) begin
        if (reset != 3)
            reset <= reset + 1;
    end

    wire rst;
    assign rst = reset == 3;

    reg we_x = 0;
    reg re_x = 0;
    reg [7:0] waddr_x = 0;
    reg [7:0] raddr_x = 0;
    wire [15:0] wdata_x;
    wire [15:0] data_x;

    dpram #(.BITS(16), .SIZE(256), .FILE("x.dat")) ram_x(.ck(ck),
        .we(we_x), .waddr(waddr_x), .wdata(wdata_x),
        .re(re_x), .raddr(raddr_x), .rdata(data_x));

    reg clr, acc_en, req;
    reg [15:0] data_y;
    wire [39:0] acc_out;
    wire acc_done;
    
    mac mac(.ck(ck), .en(acc_en), .clr(clr), .req(req), 
        .x(data_x), .y(data_y), .out(acc_out), .done(acc_done));

    wire [4:0] shift;
    assign shift = 14;
    wire [15:0] audio;
    wire overflow;
    shifter shifter(.ck(ck), .en(acc_done), .shift(shift), .in(acc_out), .out(audio), .overflow(overflow));

    always @(posedge ck) begin
        raddr_x <= raddr_x + 1;
    end
    
    initial begin

        req <= 0;
        acc_en <= 0;

        for (int i = 0; i < 5; i++) begin
            @(posedge ck);
        end

        data_y <= 16'h7fff;
        raddr_x <= 0;
        re_x <= 1;
        clr <= 1;

        @(posedge ck);
        acc_en <= 1;
        req <= 1;

        @(posedge ck);
        clr <= 0;

        for (int i = 0; i < 5; i++) begin
            @(posedge ck);
        end

        acc_en <= 0;
        req <= 0;
    end

endmodule

