
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

    generate 

        if (LENGTH == 1) begin

            reg delay = INIT;

            always @(posedge ck) begin
                delay <= in;
            end

            assign out = delay;

        end else begin

            reg [(LENGTH-1):0] delay = INIT;

            always @(posedge ck) begin
                delay <= { delay[LENGTH-2:0], in };
            end

            assign out = delay[LENGTH-1];

        end

    endgenerate

endmodule


