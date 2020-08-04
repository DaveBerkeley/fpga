
module spl
    #(parameter WIDTH=16)
(
    input wire ck,
    input wire rst,
    input wire peak_en,
    input wire decay_en,
    input wire [(WIDTH-1):0] in,
    output wire [(WIDTH-1):0] out
);

    wire [(WIDTH-1):0] uint;

    twos_complement #(.WIDTH(WIDTH))
    twos_complement (
        .ck(ck),
        .inv(in[WIDTH-1]),
        .in(in),
        .out(uint)
    );

    reg [(WIDTH-1):0] max = 0;

    always @(posedge ck) begin

        if (rst) begin
            max <= 0;
        end

        if (peak_en & (uint >= max)) begin
            max <= uint;
        end 

        if (decay_en & (max > 0)) begin
            max <= max - 1;
        end

    end

    assign out = max;

endmodule
