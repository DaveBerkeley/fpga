
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

    // Try n-wide pipe

    reg  [15:0] p_in  = 0;
    wire [15:0] p_out;

    pipe #(.LENGTH(3)) pipes [15:0] (.ck(ck), .rst(pt_rst), .in(p_in), .out(p_out));

    initial begin

        @(posedge ck);
        wait(!rst);
        @(posedge ck);

        p_in <= 16'h1234;
        @(posedge ck);
        tb_assert(p_out == 16'h0);

        p_in <= 16'haaaa;
        @(posedge ck);
        tb_assert(p_out == 16'h0);
        
        p_in <= 16'h5555;
        @(posedge ck);
        tb_assert(p_out == 16'h0);
        
        p_in <= 16'h4545;
        @(posedge ck);
        tb_assert(p_out == 16'h1234);
        
        p_in <= 16'h4321;
        @(posedge ck);
        tb_assert(p_out == 16'haaaa);
        
        @(posedge ck);
        tb_assert(p_out == 16'h5555);
        
        @(posedge ck);
        tb_assert(p_out == 16'h4545);
        
        @(posedge ck);
        tb_assert(p_out == 16'h4321);
        
        @(posedge ck);
        tb_assert(p_out == 16'h4321);
        
    end


    // Try n-wide pipe

    reg  p1_in  = 0;
    wire p1_out;

    pipe #(.LENGTH(1)) pipe1 (.ck(ck), .rst(pt_rst), .in(p1_in), .out(p1_out));

    initial begin

        @(posedge ck);
        wait(!rst);
        @(posedge ck);

        p1_in <= 1;
        @(posedge ck);
        tb_assert(p1_out == 0);

        @(posedge ck);
        tb_assert(p1_out == 1);

        @(posedge ck);
        tb_assert(p1_out == 1);

        p1_in <= 0;
        @(posedge ck);
        tb_assert(p1_out == 1);

        @(posedge ck);
        tb_assert(p1_out == 0);

    end

endmodule

