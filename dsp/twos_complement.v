
   /*
    *
    */

module twos_complement
    #(parameter WIDTH=16)
   (input wire ck, 
    input wire inv, 
    input wire [(WIDTH-1):0] in, 
    output reg [(WIDTH-1):0] out
);

    initial out = 0;

    always @(posedge ck) begin
        if (inv)
            out <= 1'b1 + ~in;
        else
            out <= in;
    end

endmodule

