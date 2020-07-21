
   /*
    *
    */

module pipe
    #(parameter LENGTH=1, parameter INIT=0)
   (input wire ck, 
    input wire rst, 
    input wire in, 
    output wire out
);

    reg [(LENGTH-1):0] delay = INIT;

    /* verilator lint_off WIDTH */
    always @(posedge ck) begin
        if (rst)
            delay <= (delay << 1) | in;
        else
            delay <= 0;
    end
    /* verilator lint_on WIDTH */

    assign out = delay[LENGTH-1];

endmodule


