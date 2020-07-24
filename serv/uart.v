
module uart_tx(
    input wire ck,
    input wire baud_ck,
    input wire [7:0] in,
    input wire we,
    output reg ready,
    output reg tx);

    reg [9:0] shift = 10'h3ff;
    reg [3:0] count = 0;

    initial ready = 1;
    initial tx = 1;

    always @(posedge ck) begin

        if (baud_ck) begin
            shift <= { 1'b1, shift[9:1] };
            if (count != 0) begin
                count <= count - 1;
            end

            ready <= count == 0;
            tx <= shift[0];
        end

        if (we & ready) begin
            shift <= { 1'b1, in, 1'b0 };
            count <= 9;
            ready <= 0;
        end

    end

endmodule

   /*
    *
    */

module uart_baud
    #(parameter DIVIDE=16)
    (input wire ck, 
    output reg baud_ck
);

    localparam WIDTH = $clog2(DIVIDE);
    reg [(WIDTH-1):0] baud = 0;

    initial baud_ck = 0;

    always @(posedge ck) begin
        /* verilator lint_off WIDTH */
        if (baud == (DIVIDE - 1)) begin
            baud <= 0;
            baud_ck <= 1;
        end else begin
            baud <= baud + 1;
            baud_ck <= 0;
        end
        /* verilator lint_on WIDTH */
    end

endmodule
