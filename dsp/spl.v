
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

   /*
    *
    */

module spl_xfer
    #(parameter WIDTH=16, ADDR_W=3)
(
    input wire ck,
    input wire rst,
    input wire run,
    input wire [(WIDTH-1):0] data_in,
    output wire [(WIDTH-1):0] data_out,
    output reg [(ADDR_W-1):0] addr = 0,
    output wire we,
    output reg done = 0,
    output reg busy = 0
);

    always @(posedge ck) begin

        if (rst) begin
            addr <= 0;
            done <= 0;
            busy <= 0;
        end

        if (run & !done) begin
            busy <= 1;
        end

        if (busy) begin

            addr <= addr + 1;

            if (addr == ((1 << ADDR_W) - 1)) begin
                done <= 1;
                busy <= 0;
            end

        end

    end

    assign data_out = busy ? data_in : 0;
    assign we = busy;

endmodule

//  FIN
