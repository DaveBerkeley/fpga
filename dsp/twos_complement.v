
   /*
    *
    */

module twos_complement(input wire ck, input wire inv, input wire [15:0] in, output reg [15:0] out);

    initial out = 0;

    always @(posedge ck) begin
        if (inv)
            out <= (~in) + 1'b1;
        else
            out <= in;
    end

endmodule

