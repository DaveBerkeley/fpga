
    /*
    *   Top module
    */

module top (input wire CLK, output wire P1A1, output wire P1A2);

assign P1A1 = 1'b1;
assign P1A2 = 1'b0;

always @(posedge CLK) begin
end

endmodule

