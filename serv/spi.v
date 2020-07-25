
module spi(
    input wire ck,
    output wire cs,
    output wire sck,
    output wire mosi,
    input wire miso,

    input wire [7:0] code,
    input wire [23:0] addr,
    input wire tx_addr,
    input wire req,
    output reg [31:0] rdata,
    output wire ready
);

    initial begin
        rdata = 0;
    end

    reg [31:0] tx = 32'b0;
    reg [6:0] bit_count = 0;
    wire sending;
    assign sending = bit_count != 0;

    reg clock = 0;

    function [7:0] reverse(input [7:0] d);

        begin
            reverse = { d[0], d[1], d[2], d[3], d[4], d[5], d[6], d[7] };
        end

    endfunction

    reg [31:0] rx = 32'b0;

    always @(posedge ck) begin

        clock <= !clock;

        if (req) begin
            tx <= { reverse(addr[7:0]), reverse(addr[15:8]), reverse(addr[23:16]), reverse(code) };

            bit_count <= tx_addr ? (1 + 32 + 32) : (1 + 8 + 32);

            clock <= 0;
        end

        if (clock) begin
            if (sending) begin

                if (bit_count == 1) begin
                    rdata <= rx;
                end

                bit_count <= bit_count - 1;
                tx <= { 1'b0, tx[31:1] };
                rx <= { rx[30:0], miso };

            end
        end
    end

    assign mosi  = sending ? tx[0] : 1;
    assign sck   = sending ? clock : 0;
    assign cs    = !sending;
    assign ready = !sending;

endmodule
