
   /*
    *
    */

module pipe(input wire ck, input wire rst, input wire in, output wire out);

    parameter LENGTH=1;

    reg [(LENGTH-1):0] delay;

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


