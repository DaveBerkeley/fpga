
`default_nettype none
`timescale 1ns / 100ps

task assert_x(input test);

    begin
        if (test !== 1)
        begin
            $display("ASSERTION FAILED in %m");
            $finish;
        end
    end

endtask

module corr_fetch
    #(parameter ADDR_W=8, parameter COUNT_W=4)
   (input wire ck,
    input wire en,
    input wire start,
    input wire [(COUNT_W-1):0] count,
    input wire [(ADDR_W-1):0] start_addr,
    output reg [(ADDR_W-1):0] raddr,
    output reg ren,
    output reg done
);

    reg [(COUNT_W-1):0] counter = 0;

    initial begin
        raddr = 0;
        ren = 0;
        done = 0;
    end

    always @(posedge ck) begin
        if (en) begin
            if (start) begin
                raddr <= start_addr;
                ren <= 1;
                done <= 0;
                counter <= count;
            end else begin
                if (counter > 1) begin
                    counter <= counter - 1;
                    raddr <= raddr + 1;
                end else begin
                    if (ren)
                        done <= 1;
                    ren <= 0;
                    raddr <= 0;
                end
            end
        end
    end

endmodule

   /*
    *   Returns the index of the highest set bit,
    *   first normalising -vew numbers
    */

module highest_bit
    #(parameter WIDTH=40, parameter LEVEL_W=$clog2(WIDTH))
   (input wire ck,
    input wire signed [(WIDTH-1):0] in,
    output reg [(LEVEL_W-1):0] out
);

    wire [(WIDTH-1):0] normal;

    assign normal = in[WIDTH-1] ? ~in : in;

    wire [(WIDTH-1):0] bit_1;
    wire [(WIDTH-1):0] bit_2;
    wire [(WIDTH-1):0] bit_4;
    wire [(WIDTH-1):0] bit_8;
    wire [(WIDTH-1):0] bit_16;
    wire [(WIDTH-1):0] bit_32;
    wire [(WIDTH-1):0] bit_64;

    assign bit_1  = normal | (normal >> 1);
    assign bit_2  = bit_1  | (bit_1 >> 2);
    assign bit_4  = bit_2  | (bit_2 >> 4);
    assign bit_8  = bit_4  | (bit_4 >> 8);
    assign bit_16 = bit_8  | (bit_8 >> 16);
    assign bit_32 = bit_16 | (bit_16 >> 32);
    assign bit_64 = bit_32 | (bit_32 >> 64);

    wire [(WIDTH-1):0] hi_bit;

    assign hi_bit = bit_64 ^ (bit_64 >> 1);

    integer i;

    always @(posedge ck) begin
        out <= 0;
        for (i = 0; i < WIDTH; i = i + 1) begin
            if (hi_bit[i])
                out <= i;
        end
    end

endmodule

   /*
    *
    */

module tb ();

    reg ck = 0;

    always #42 ck <= !ck;

    initial begin
        $dumpfile("correlator.vcd");
        $dumpvars(0, tb);
        #500000 $finish;
    end

    reg [1:0] reset = 0;

    always @(posedge ck) begin
        if (reset != 3)
            reset <= reset + 1;
    end

    wire rst;
    assign rst = reset == 3;

    reg we_x = 0;
    wire re_x;
    reg [7:0] waddr_x = 0;
    wire [7:0] raddr_x;
    wire [15:0] wdata_x;
    wire [15:0] data_x;

    wire fetch_done;
    dpram #(.BITS(16), .SIZE(256), .FILE("x.dat")) ram_x(.ck(ck),
        .we(we_x), .waddr(waddr_x), .wdata(wdata_x),
        .re(re_x), .raddr(raddr_x), .rdata(data_x));

    localparam ADDR_W = 8;
    localparam COUNT_W = 5;
    reg start = 0;
    reg [(COUNT_W-1):0] count = 12;
    wire fetching;
    corr_fetch #(.ADDR_W(ADDR_W), .COUNT_W(COUNT_W)) 
        fetch_x(.ck(ck), .en(1'b1), .start(start), .count(count),
            .start_addr(8'h0), .raddr(raddr_x), .ren(fetching), .done(fetch_done));

    assign re_x = fetching;

    reg clr, acc_en, req = 0;
    reg [15:0] data_y;
    wire [39:0] acc_out;
    wire acc_done;
 
    mac mac(.ck(ck), .en(acc_en), .clr(clr), .req(req), 
        .x(data_x), .y(data_y), .out(acc_out), .done(acc_done));

    wire [5:0] agc;
    highest_bit level(.ck(ck), .in(acc_out), .out(agc));

    wire [4:0] shift;
    assign shift = 14;
    wire [15:0] audio;
    shifter shifter(.ck(ck), .en(1'b1), .shift(shift), .in(acc_out), .out(audio));

    //  highest_bit() test

    wire [5:0] level_out;
    reg [39:0] level_in = 0;
    highest_bit level_test(.ck(ck), .in(level_in), .out(level_out));

    task test_level(input [39:0] in, input [5:0] result);

        begin
            level_in <= in;
            @(posedge ck);
            @(posedge ck);
            //$display("level_test '%x' '%d', expect '%d'", in, level_out, result);
            assert_x(level_out == result);
        end

    endtask

    integer ii;

    initial begin

        $display("test highest_bit()");

        level_in <= 0;
        @(posedge ck);

        test_level(40'h0000000000, 0);
        test_level(40'h0000000001, 0);
        test_level(40'h0000000003, 1);
        test_level(40'h1000000001, 36);
        test_level(40'h2002222001, 37);
        test_level(40'h7002222001, 38);
        test_level(40'h7fffffffff, 38);

        for (ii = 0; ii < 39; ii = ii + 1) begin
            test_level(1 << ii, ii);
        end

        test_level(40'h8000000000, 38);
        test_level(40'hA000000000, 38);
        test_level(40'hA123456789, 38);
        test_level(40'hffffffffff, 0);
        test_level(40'hffffffffef, 4);
        test_level(40'hfeffffffef, 32);

    end

    //  Test

    always @(posedge ck) begin
        acc_en <= fetching;
        req <= fetching;

        // set clr for the first cycle of the fetch
        if (fetching & !req)
            clr <= 1;
        if (clr)
            clr <= 0;
    end

    initial begin

        for (int i = 0; i < 5; i++) begin
            @(posedge ck);
        end

        data_y <= 16'h7fff;
        start <= 1;

        @(posedge ck);
        start <= 0;

        // Wait for acc_done ...

    end

endmodule

