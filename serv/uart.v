
module uart_tx(
    input wire ck,
    input wire baud_ck,
    input wire [7:0] in,
    input wire we,
    output reg ready,
    output reg tx);

    reg [9:0] shift = 10'h3ff;
    reg [3:0] count = 0;

    always @(posedge ck) begin

        if (baud_ck) begin
            shift <= { 1'b1, shift[9:1] };
            if (count != 0) begin
                count <= count - 1;
            end

            ready <= count == 0;
            tx <= shift[0];
        end

        if (we) begin
            shift <= { 1'b1, in, 1'b0 };
            count <= 9;
            ready <= 0;
        end

    end

endmodule

