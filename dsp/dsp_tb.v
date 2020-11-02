
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

    reg        wb_dbus_cyc = 0;
    reg        wb_dbus_we = 0;
    wire       wb_dbus_ack;
    reg [3:0]  wb_dbus_sel = 0;
    reg [31:0] wb_dbus_adr = 32'hZ;
    reg [31:0] wb_dbus_dat = 32'hZ;
    wire [31:0] wb_dbus_rdt;

    task write(input [31:0] addr, input [31:0] data);
        begin
            wb_dbus_adr <= addr;
            wb_dbus_dat <= data;
            wb_dbus_sel <= 4'b1111;
            wb_dbus_we <= 1;
            wb_dbus_cyc <= 1;
            @(posedge ck);
            wait(!wb_dbus_cyc);
            @(posedge ck);
        end
    endtask

    reg [31:0] rd_data = 32'hZ;

    task read(input [31:0] addr);

            wb_dbus_adr <= addr;
            wb_dbus_cyc <= 1;
            @(posedge ck);
            wait(!wb_dbus_cyc);
            rd_data <= wb_dbus_rdt;

    endtask

    reg [31:0] poll_addr = 0;

    always @(posedge ck) begin
        if (poll_addr != 0) begin
            read(poll_addr);
        end
    end

    always @(posedge ck) begin
        if (wb_dbus_ack) begin
            wb_dbus_adr <= 32'hZ;
            wb_dbus_dat <= 32'hZ;
            wb_dbus_sel <= 0;
            wb_dbus_we <= 0;
            wb_dbus_cyc <= 0;
        end
    end

    // _rdt should be zero if no cyc active
    always @(posedge ck) begin
        if (!wb_dbus_cyc) begin
            tb_assert(wb_dbus_rdt == 0);
        end
    end

    wire sck, ws, sd_out, sd_gen;
    assign sck = 0;
    assign ws = 0;
    wire [7:0] test;
    wire engine_ready;

    audio_engine engine(.ck(ck), 
        .wb_rst(rst),
        .wb_dbus_cyc(wb_dbus_cyc),
        .wb_dbus_sel(wb_dbus_sel),
        .wb_dbus_we(wb_dbus_we),
        .wb_dbus_adr(wb_dbus_adr),
        .wb_dbus_dat(wb_dbus_dat),
        .ack(wb_dbus_ack),
        .rdt(wb_dbus_rdt),
        .sck(sck), 
        .ws(ws),
        .sd_out0(sd_out), 
        .sd_in0(sd_gen),
        .ready(engine_ready),
        .test(test)
    );

    integer i;

    localparam COEF   = 32'h60000000;
    localparam RESULT = 32'h61000000;
    localparam STATUS = 32'h62000000;
    localparam RESET  = 32'h63000000;
    localparam INPUT  = 32'h64000000;

    initial begin
        wait(!rst);
        @(posedge ck);
        @(posedge ck);
        @(posedge ck);

        // Test fetching opcode
        i = COEF;
        write(i, 32'h08000000); i += 4; // capture 0
        write(i, 32'h48081234); i += 4; // MACZ offset=01 chan=0 gain=1234
        write(i, 32'h78000000); i += 4; // HALT
        write(i, 32'h78000000); i += 4; // HALT

        // Reset the dsp
        write(RESET, 0);
        @(posedge ck);
        tb_assert(!engine_ready);

        // Poll for ready
        poll_addr <= STATUS;
        wait(rd_data & 32'h1);
        poll_addr <= 32'h0;
        tb_assert(engine_ready);
        @(posedge ck);

        // read capture reg
        read(STATUS + 4);
        // check we captured the op-code above
        @(posedge ck);
        tb_assert(rd_data == 32'h48081234);
        // PASS

        // set control : allow_audio_writes
        write(STATUS, 1);
        @(posedge ck);

        // Check multiplier input

        // set_audio
        write(INPUT + ('h104 * 2), 16'h1234); 
        @(posedge ck);

        i = COEF;
        write(i, 32'h48213456); i += 4; // MACZ offset=04 chan=1 gain=3456
        write(i, 32'h00000000); i += 4; // NOOP
        write(i, 32'h00000000); i += 4; // NOOP
        write(i, 32'h08100000); i += 4; // CAPT 2 mul in a/b
        write(i, 32'h78000000); i += 4; // HALT
        write(i, 32'h78000000); i += 4; // HALT

        // Reset the dsp
        write(RESET, 0);
        @(posedge ck);
        wait(engine_ready);
        @(posedge ck);

    end

endmodule

