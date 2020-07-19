
   /*
    *
    */

module top (
    input wire CLK
);

    wire ck;
    assign ck = CLK;

    reg clr, acc_en, req;
    reg [15:0] x;
    reg [15:0] y;
    /* verilator lint_off UNUSED */
    wire [39:0] acc_out;
    wire acc_done;
    /* verilator lint_on UNUSED */

    initial begin
        clr = 0;
        acc_en = 0;
        req = 0;
        x = 16'h1234;
        y = 16'h1234;
    end
    
    mac mac(.ck(ck), .en(acc_en), .clr(clr), .req(req), 
        .x(x), .y(y), .out(acc_out), .done(acc_done));
    
endmodule


