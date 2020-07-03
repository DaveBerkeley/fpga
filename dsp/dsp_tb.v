
`default_nettype none
`timescale 1ns / 100ps

module tb ();

    initial begin
        $dumpfile("dsp.vcd");
        $dumpvars(0, tb);
        #5000000 $finish;
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

    integer i;

    initial begin
        @(posedge ck);
        @(posedge ck);
        @(posedge ck);
        @(posedge ck);
        @(posedge ck);
        // Setup the coefficient RAM
        i = 32'h60000000;
        write(i, 32'hffffffff); i += 4; // NOOP
        write(i, 32'h2000ffff + (3'h7 << 25)); i += 4; // Capture (match=n)
        write(i, 32'h82000001); i += 4; 
        write(i, 32'h84100000); i += 4;
        write(i, 32'h82010001); i += 4;
        write(i, 32'h84110000); i += 4;
        write(i, 32'h82020001); i += 4;
        write(i, 32'h84120000); i += 4;
        write(i, 32'h82030001); i += 4;
        write(i, 32'h84130000); i += 4;

        write(i, 32'h00000000); i += 4; // HALT
        write(i, 32'h00000000); i += 4; // HALT
        write(i, 32'h00000000); i += 4; // HALT
 
        // set control register
        write(32'h62000000, 1 + (1 << 1)); // allow_audio_writes

        // Write to audio RAM
        i = 32'h64000000;
        write(i, 32'h0000aaaa); i += 4;
        write(i, 32'h00005555); i += 4;
        write(i, 32'h0000aaaa); i += 4;
        write(i, 32'h00005555); i += 4;

        i = 32'h64000000 + ((1 * 32) * 4);
        write(i, 32'h00001111); i += 4;

        i = 32'h64000000 + ((2 * 32) * 4);
        write(i, 32'h00002222); i += 4;

        i = 32'h64000000 + ((3 * 32) * 4);
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

