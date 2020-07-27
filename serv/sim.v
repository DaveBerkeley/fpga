
task tb_assert(input test);

    begin
        if (!test) begin
            $display("ASSERTION FAILED in %m");
            $finish;
        end
    end

endtask

module top;

endmodule

