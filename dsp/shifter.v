
   /*
    *
    */

module shifter
    #(parameter IN_W=40, OUT_W=16, SHIFT_W=5)
    ( input wire ck,
    input wire en,
    input wire [SHIFT_W-1:0] shift,
    input wire [IN_W-1:0] in,
    output reg [OUT_W-1:0] out
);

    initial out = 0;

    wire [OUT_W-1:0] shifted;

    genvar i;

    generate

        for (i = 0; i < OUT_W; i = i + 1) begin
            assign shifted[i] = in[i+shift];
        end

    endgenerate

    always @(posedge ck) begin
        if (en) begin
            out <= shifted;
        end
    end

endmodule


