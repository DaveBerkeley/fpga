
   /*
    *
    */

module addr_adder(
    input wire ck,
    input wire [FRAME_W-1:0] frame,
    input wire [FRAME_W-1:0] offset,
    input wire [CHAN_W-1:0] chan,
    output reg [(FRAME_W+CHAN_W)-1:0] addr
);

    parameter FRAME_W = 6;
    parameter CHAN_W = 3;

    always @(posedge ck) begin
        addr <= { chan, frame + offset };
    end

endmodule

