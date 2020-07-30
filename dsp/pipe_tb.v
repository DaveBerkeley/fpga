
`default_nettype none
`timescale 1ns / 100ps

module tb ();

    initial begin
        $dumpfile("dsp.vcd");
        $dumpvars(0, tb);
        #500000 $finish;
    end

    reg ck = 0;

    always #42 ck <= !ck;

    wire rst;

    reset #(.LENGTH(4)) reset (.ck(ck), .rst_req(1'b0), .rst(rst));

    //  Test pipe()

    reg pt_rst = 0;
    reg pt_in = 0;
    wire pt_out;

    pipe #(.LENGTH(4)) pipe_test(.ck(ck), .rst(pt_rst), .in(pt_in), .out(pt_out));

    integer pt_i;

    initial begin
        $display("test pipe()");
        tb_assert(pt_out == 0);
        @(posedge ck);
        pt_rst <= 1;
        pt_in <= 1;
        tb_assert(pt_out == 0);

        for (pt_i = 0; pt_i < 4; pt_i = pt_i + 1) begin
            @(posedge ck);
            tb_assert(pt_out == 0);
        end
 
        for (pt_i = 0; pt_i < 4; pt_i = pt_i + 1) begin
            @(posedge ck);
            tb_assert(pt_out == 1);
        end
 
        pt_in <= 0;
        @(posedge ck);
        pt_in <= 1;

        @(posedge ck);
        tb_assert(pt_out == 1);
        @(posedge ck);
        tb_assert(pt_out == 1);
        @(posedge ck);
        tb_assert(pt_out == 1);
        @(posedge ck);
        tb_assert(pt_out == 0);
        @(posedge ck);
        tb_assert(pt_out == 1);
        @(posedge ck);
        tb_assert(pt_out == 1);
        @(posedge ck);
        tb_assert(pt_out == 1);

        pt_in <= 0;
        for (pt_i = 0; pt_i < 4; pt_i = pt_i + 1) begin
            @(posedge ck);
            tb_assert(pt_out == 1);
        end
        for (pt_i = 0; pt_i < 4; pt_i = pt_i + 1) begin
            @(posedge ck);
            tb_assert(pt_out == 0);
        end
    end

endmodule

