
module tx(
    input wire ck,
    input wire tx,
    input wire [31:0] data,
    output wire led_out,
    output wire led_ck,
    output reg busy
);

initial busy = 0;

reg [31:0] shift = 0;
reg [5:0] counter = 0;

always @(posedge ck) begin

    if (tx && !busy) begin
        shift <= data;
        counter <= 0;
        busy <= 1;
    end else begin
        shift <= { shift[30:0], 1'b0 };
        counter <= counter + 1;
        if (counter == 31)
            busy <= 0;
    end

end

assign led_ck = busy ? (!ck) : 1;
assign led_out = shift[31];


endmodule

    /*
    *
    */

module top (input CLK, output P1A1, output P1A2);

wire led_data;
wire led_ck;

// Assign the IO

assign P1A1 = led_data;
assign P1A2 = led_ck;

reg [31:0] data;
wire busy;
reg do_tx = 0;

tx tx_(.ck(CLK), .tx(do_tx), .data(data), .led_out(led_data), .led_ck(led_ck), .busy(busy));

reg [3:0] word = 0;
reg [23:0] colour = 0;
reg [2:0] cycle = 0;

task set_colour(input [7:0] r, input [7:0] g, input [7:0] b);

begin
    data <= { 8'hE4, b, g, r };  
    do_tx <= 1;
end

endtask

always @(posedge CLK) begin

    if (! (busy || do_tx)) begin

        word <= word + 1;

        if (word == 0) begin
            cycle <= cycle + 1;

            if (cycle == 0)
                colour <= colour + 1;
        end

        case (word)

            0   :   begin data <= 32'h0; do_tx <= 1; end

            1   :   begin set_colour(8'h00, 8'h00, 8'hff); end
            2   :   begin set_colour(8'h00, 8'h80, 8'h80); end
            3   :   begin set_colour(8'hff, 8'hff, 8'h00); end
            4   :   begin set_colour(8'h80, 8'h80, 8'h00); end
            5   :   begin set_colour(8'hff, 8'h00, 8'h00); end
            6   :   begin set_colour(8'h80, 8'h00, 8'h80); end
            7   :   begin set_colour(8'h80, 8'h00, 8'h80); end
            8   :   begin set_colour(8'hff, 8'h00, 8'h00); end
            9   :   begin set_colour(8'h80, 8'h80, 8'h00); end
            10  :   begin set_colour(8'h00, 8'hff, 8'h00); end
            11  :   begin set_colour(8'h00, 8'h80, 8'h80); end
            12  :   begin set_colour(8'h00, 8'h00, 8'hff); end
            13  :   begin set_colour(8'h00, 8'h00, 8'h00); end

            14  :   begin data <= 32'hff_ff_ff_ff;  do_tx <= 1; end

            default : data <= 0;

        endcase

    end

    if (busy)
        do_tx <= 0;

end

endmodule

