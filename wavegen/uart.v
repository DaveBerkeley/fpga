   /*
    *
    */

module uart(
    input wire ck, 
    input wire [7:0] tx_data, 
    output wire tx,
    output wire ready,
    output wire baud
);

    reg [6:0] baud_counter = 0;

    always @(negedge ck) begin
        if (baud_counter < 104)
            baud_counter <= baud_counter + 1;
        else
            baud_counter <= 0;
    end

    reg [3:0] count = 0;
    reg [9:0] shift;

    always @(negedge ck) begin
        if (baud_counter == 0) begin
            
            if (count == 0)
                shift <= { 1'b1, tx_data, 1'b0 };
            else
                shift <= { 1'b1, shift[9:1] };

            if (count == 10)
                count <= 0;
            else
                count <= count + 1;            
        end
    end

    assign tx = shift[0];
    assign ready = count == 0;
    assign baud = baud_counter >= 50;

endmodule


