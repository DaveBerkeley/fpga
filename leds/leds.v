
   /*
    *   Send a frame of data to SK9822 LEDs
    */

module tx_led(
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

module led_sk9822 (input clk, output led_data, output led_ck,
                    output reg re, output reg [3:0] raddr, 
                    input wire [23:0] rdata
);

reg [31:0] data;
wire busy;
reg do_tx = 0;

tx_led tx_(.ck(clk), .tx(do_tx), .data(data), .led_out(led_data), .led_ck(led_ck), .busy(busy));

task send(input [31:0] di);

    begin
        data <= di;
        do_tx <= 1;
    end

endtask

task read_data(input [3:0] idx);

    begin
        raddr <= idx;
        re <= 1;
    end

endtask

reg [3:0] led_idx = 0;

always @(negedge clk) begin

    if (re) begin
        data <= { 8'hF8, rdata[23:0] };
        do_tx <= 1;
        re <= 0;
    end

    if (busy)
        do_tx <= 0;

    if (! (busy || do_tx || re)) begin

        led_idx <= led_idx + 1;

        case (led_idx)

            0   :   begin send(32'h0); end

            1   :   begin read_data(0);  end
            2   :   begin read_data(1);  end
            3   :   begin read_data(2);  end
            4   :   begin read_data(3);  end
            5   :   begin read_data(4);  end
            6   :   begin read_data(5);  end
            7   :   begin read_data(6);  end
            8   :   begin read_data(7);  end
            9   :   begin read_data(8);  end
            10  :   begin read_data(9);  end
            11  :   begin read_data(10); end
            12  :   begin read_data(11); end

            13  :   begin send(32'hff_ff_ff_ff); end

            default : data <= 0;

        endcase

    end

end

endmodule

   /*
    *   Write to LED ram
    */

module ram_write(input wire clk, output reg we, output reg [3:0] waddr, output reg [31:0] wdata);

reg [12:0] slower = 0;
reg [7:0] red = 0;

always @(negedge clk) begin

    slower <= slower + 1;

    if (slower == 0) begin
        red <= red + 1;
        // write to RAM
        if (red == 1) begin
            if (waddr == 11) 
                waddr <= 0;
            else
                waddr <= waddr + 1;
        end

        wdata <= { 8'h0, red, 8'h0, 8'h0 };
        we <= 1;
    end

    if (we)
        we <= 0;

end
   
endmodule

