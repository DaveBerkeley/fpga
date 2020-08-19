
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

module level 
#(parameter IN_W=24, BITS = $clog2(IN_W))
(
    input wire ck,
    input wire en,
    input wire [IN_W-1:0] in,
    output wire [BITS-1:0] level,
    output wire ready
);

    reg [IN_W-1:0] shift = 0;

    reg [BITS-1:0] bits = 0;
    reg busy = 0;

    always @(posedge ck) begin
        if (en) begin
            shift <= in;
            bits <= 0;
            busy <= 1;
        end 

        if (busy && !en) begin
            if (shift[IN_W-1] != shift[IN_W-2]) begin
                // top bits differ, done
                busy <= 0;
            end else begin
                bits <= bits + 1;
                shift <= { shift[IN_W-1], shift[IN_W-2:0], !shift[IN_W-1] };
            end
        end
    end

    assign level = bits;
    assign ready = !busy;

endmodule

//  FIN
