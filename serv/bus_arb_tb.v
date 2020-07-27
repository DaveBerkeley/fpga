
`default_nettype none
`timescale 1ns / 100ps

task tb_assert(input test);

    begin
        if (!test) begin
            $display("ASSERTION FAILED in %m");
            $finish;
        end
    end

endtask

   /*
    *
    */

module top (output wire TX);

    wire led;
    assign TX = led;

    initial begin
        $dumpfile("serv.vcd");
        $dumpvars(0, top);
        #500000 $finish;
    end

    reg CLK = 0;

    always #7 CLK <= !CLK;

endmodule

