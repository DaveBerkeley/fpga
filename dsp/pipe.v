
   /*
    *
    */

module pipe
    #(parameter LENGTH=1, parameter INIT=0)
   (input wire ck, 
    /* verilator lint_off UNUSED */
    input wire rst, // TODO : remove me 
    /* verilator lint_on UNUSED */
    input wire in, 
    output wire out
);

    reg [(LENGTH-1):0] delay = INIT;

    generate 

        if (LENGTH == 1) begin

            always @(posedge ck) begin
                delay <= in;
            end

        end else begin

            always @(posedge ck) begin
                delay <= { delay[LENGTH-2:0], in };
            end

        end

    endgenerate

    assign out = delay[LENGTH-1];

endmodule


