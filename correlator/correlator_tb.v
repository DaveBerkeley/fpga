
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

    reg clr, acc_en, req;
    reg [15:0] data_x;
    reg [15:0] data_y;
    wire [39:0] acc_out;
    wire acc_done;
    
    top xx(.ck(ck), .en(acc_en), .clr(clr), .req(req), 
        .x(data_x), .y(data_y), .out(acc_out), .done(acc_done));
    
    initial begin

        req <= 0;
        acc_en <= 0;

        @(posedge ck);
        @(posedge ck);
        @(posedge ck);
        @(posedge ck);
        @(posedge ck);

        data_x <= 16'h1234;
        data_y <= 16'h0001;
        clr <= 1;
        acc_en <= 1;
        req <= 1;

        @(posedge ck);
        data_x <= 16'h1111;
        data_y <= 16'h0001;
        clr <= 0;

        @(posedge ck);
        data_x <= 16'h0001;
        data_y <= 16'h2222;
        clr <= 0;

        @(posedge ck);
        acc_en <= 0;
        req <= 0;
    end

endmodule

