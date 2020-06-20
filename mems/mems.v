
module top (input CLK, output LED1);

reg [15:0] count = 16'h0000;

always @(posedge CLK) begin
   count <= count + 1;
end

assign LED1 = count[15];

endmodule
