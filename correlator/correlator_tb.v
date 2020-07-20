
`default_nettype none
`timescale 1ns / 100ps

module corr_fetch
    #(parameter ADDR_W=8, parameter COUNT_W=4)
   (input wire ck,
    input wire en,
    input wire start,
    input wire [(COUNT_W-1):0] count,
    input wire [(ADDR_W-1):0] start_addr,
    output reg [(ADDR_W-1):0] raddr,
    output reg ren,
    output reg done
);

    reg [(COUNT_W-1):0] counter = 0;

    initial begin
        raddr = 0;
        ren = 0;
        done = 0;
    end

    always @(posedge ck) begin
        if (en) begin
            if (start) begin
                raddr <= start_addr;
                ren <= 1;
                done <= 0;
                counter <= count;
            end else begin
                if (counter > 1) begin
                    counter <= counter - 1;
                    raddr <= raddr + 1;
                end else begin
                    if (ren)
                        done <= 1;
                    ren <= 0;
                    raddr <= 0;
                end
            end
        end
    end

endmodule

   /*
    *
    */

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
    wire re_x;
    reg [7:0] waddr_x = 0;
    wire [7:0] raddr_x;
    wire [15:0] wdata_x;
    wire [15:0] data_x;

    wire fetch_done;
    dpram #(.BITS(16), .SIZE(256), .FILE("x.dat")) ram_x(.ck(ck),
        .we(we_x), .waddr(waddr_x), .wdata(wdata_x),
        .re(re_x), .raddr(raddr_x), .rdata(data_x));

    localparam ADDR_W = 8;
    localparam COUNT_W = 5;
    reg start = 0;
    reg [(COUNT_W-1):0] count = 12;
    wire fetching;
    corr_fetch #(.ADDR_W(ADDR_W), .COUNT_W(COUNT_W)) 
        fetch_x(.ck(ck), .en(1'b1), .start(start), .count(count),
            .start_addr(8'h0), .raddr(raddr_x), .ren(fetching), .done(fetch_done));

    assign re_x = fetching;

    reg clr, acc_en, req = 0;
    reg [15:0] data_y;
    wire [39:0] acc_out;
    wire acc_done;
 
    mac mac(.ck(ck), .en(acc_en), .clr(clr), .req(req), 
        .x(data_x), .y(data_y), .out(acc_out), .done(acc_done));

    wire [4:0] shift;
    assign shift = 14;
    wire [15:0] audio;
    shifter shifter(.ck(ck), .en(1'b1), .shift(shift), .in(acc_out), .out(audio));

    always @(posedge ck) begin
        acc_en <= fetching;
        req <= fetching;

        // set clr for the first cycle of the fetch
        if (fetching & !req)
            clr <= 1;
        if (clr)
            clr <= 0;
    end

    initial begin

        for (int i = 0; i < 5; i++) begin
            @(posedge ck);
        end

        data_y <= 16'h7fff;
        start <= 1;

        @(posedge ck);
        start <= 0;

        // Wait for acc_done ...

    end

endmodule

