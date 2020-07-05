
`default_nettype none
`timescale 1ns / 100ps

module tb ();

    initial begin
        $dumpfile("dsp.vcd");
        $dumpvars(0, tb);
        #50000 $finish;
    end

    reg ck = 0;

    always #42 ck <= !ck;

    reg [1:0] reset_cnt = 0;
    wire rst = & reset_cnt;

    always @(posedge ck) begin
        if (!rst)
            reset_cnt <= reset_cnt + 1;
    end

    reg        iomem_valid;
    wire       iomem_ready;
    reg [3:0]  iomem_wstrb;
    reg [31:0] iomem_addr;
    reg [31:0] iomem_wdata;
    wire [31:0] iomem_rdata;

    // Write audio test data into memory

    task write(input [31:0] addr, input [31:0] data);
        begin
            @(posedge ck);
            iomem_addr <= addr;
            iomem_wdata <= data;
            iomem_wstrb <= 4'b1111;
            iomem_valid <= 1;
            @(posedge ck);
            @(posedge ck);
        end
    endtask

    // Simulate removing iomem_valid
    always @(posedge ck) begin
        if (iomem_ready || !rst) begin
            iomem_valid <= 0;
            iomem_wstrb <= 0;            
            iomem_addr <= 32'hZ;
            iomem_wdata <= 32'hZ;
        end
    end

    task write_opcode;
        
        input [31:0] addr;
        input [6:0] opcode;
        input [4:0] offset;
        input [3:0] chan;
        input [15:0] gain;

        integer i;

        begin
            i = gain + (chan << 16) + (offset << 20) + (opcode << 25); 
            write(addr, i);
            $display("%h", i);
        end

    endtask

    task capture;

        input [31:0] addr;
        input [2:0] code;

        begin
            write_opcode(addr, 7'b0010000 + code, 0, 0, 0);
        end

    endtask

    task noop;

        input [31:0] addr;

        begin
            write_opcode(addr, 7'b0000000, 0, 0, 0);
        end

    endtask

    integer i;

    initial begin
        @(posedge ck);
        @(posedge ck);
        @(posedge ck);
        @(posedge ck);
        @(posedge ck);
        // Setup the coefficient RAM
        i = 32'h60000000;


        //write_opcode(i, 7'b1000010, 1, 0, 3); i += 4; // MAC N
        //write_opcode(i, 7'b1000000, 2, 0, 3); i += 4; // MAC
        //write_opcode(i, 7'b1000010, 3, 0, 3); i += 4; // MAC N
        //write_opcode(i, 7'b1010000, 0, 0, 0); i += 4; // SAVE

        //noop(i); i += 4;

        //write_opcode(i, 7'b1000001, 0, 0, 3); i += 4; // MAC Z
        //write_opcode(i, 7'b1000000, 1, 0, 3); i += 4; // MAC
        //write_opcode(i, 7'b1000000, 2, 0, 3); i += 4; // MAC
        //write_opcode(i, 7'b1000000, 3, 0, 3); i += 4; // MAC
        //write_opcode(i, 7'b1010000, 0, 0, 8); i += 4; // SAVE

        //write_opcode(i, 7'b1111111, 0, 0, 0); i += 4; // HALT
        //write_opcode(i, 7'b1111111, 0, 0, 0); i += 4; // HALT
        //capture(i, 7); i += 4; // CAPTURE

        write_opcode(i, 7'b1000010, 0, 0, 1); i += 4; // MAC Z
        write_opcode(i, 7'b1000000, 1, 0, 10); i += 4; // MAC
        write_opcode(i, 7'b1000000, 2, 0, 100); i += 4; // MAC
        capture(i, 7); i += 4; // CAPTURE
        write_opcode(i, 7'b1000000, 3, 0, 1000); i += 4; // MAC
        write_opcode(i, 7'b1111111, 0, 0, 0); i += 4; // HALT
        write_opcode(i, 7'b0000000, 0, 0, 0); i += 4; // NOOP
        write_opcode(i, 7'b0000000, 0, 0, 0); i += 4; // NOOP
 
        // set control register
        write(32'h62000000, 1 + (1 << 1)); // allow_audio_writes

        // Write to audio RAM
        i = 32'h64000000;
        write(i, 32'h00001234); i += 4;
        write(i, 32'h00001111); i += 4;
        write(i, 32'h00002222); i += 4;
        write(i, 32'h00003333); i += 4;
        write(i, 32'h00004444); i += 4;

        reset_cnt <= 0;
    end

    /* verilator lint_off UNUSED */
    wire [7:0] test;
    /* verilator lint_on UNUSED */

    audio_engine engine(.ck(!ck), .rst(rst),
        .iomem_valid(iomem_valid),
        .iomem_ready(iomem_ready),
        .iomem_wstrb(iomem_wstrb),
        .iomem_addr(iomem_addr),
        .iomem_wdata(iomem_wdata),
        .iomem_rdata(iomem_rdata),
        .test(test)
    );

endmodule

