
module sk9822_peripheral
#(parameter ADDR=0)
(
    input wire wb_clk,
    input wire wb_rst,
    input wire wb_dbus_cyc,
    input wire wb_dbus_we,
    /* verilator lint_off UNUSED */
    input wire [31:0] wb_dbus_adr,
    /* verilator lint_on UNUSED */
    input wire [31:0] wb_dbus_dat,
    output wire ack,
    output reg led_ck,
    output wire led_data
);

    // For description of protocol see :
    // https://cpldcpu.wordpress.com/2016/12/13/sk9822-a-clone-of-the-apa102/

    reg enabled = 0;

    //  Chip Select to enable write access to DP_RAM

    wire cyc;
 
    chip_select #(.ADDR(ADDR), .WIDTH(8))
    chip_select(
        .wb_ck(wb_clk),
        .addr(wb_dbus_adr[31:24]),
        .wb_cyc(wb_dbus_cyc),
        .wb_rst(wb_rst),
        .ack(ack),
        .cyc(cyc)
    );

    always @(posedge wb_clk) begin
        if (cyc) begin
            enabled <= wb_dbus_adr[5:2] != 4'hF;
        end
    end

    //  DP_RAM hold the LED values
    //
    //  xxLL BB GG RR (LL = brightness)

    wire ram_re;
    reg [3:0] ram_addr = 0;
    /* verilator lint_off UNUSED */
    wire [31:0] ram_data;
    /* verilator lint_on UNUSED */

    assign ram_re = 1;
 
    dpram #(.BITS(32), .SIZE(16))
    dpram(   
        .ck(wb_clk),
        .we(ack & wb_dbus_we),
        .waddr(wb_dbus_adr[5:2]),
        .wdata(wb_dbus_dat),
        .re(ram_re),
        .raddr(ram_addr),
        .rdata(ram_data)
    );

    //  The LED Clock is divided down from sys clock

    localparam PRESCALE = 2;
    reg [PRESCALE-1:0] prescale = 0;

    always @(posedge wb_clk) begin
        prescale <= prescale + 1;
    end

    wire led_en;
    assign led_en = prescale == 0;
    wire led_half;
    assign led_half = prescale == ((1<<PRESCALE) / 2);

    reg [31:0] shift = 0;
    reg [4:0] bit_count = 0;

    // Each LED data frame is 0xEx BB GG RR
    wire [31:0] tx_data;
    assign tx_data = { 4'he, ram_data[27:0] };

    always @(posedge wb_clk) begin

        if (led_en) begin
            bit_count <= bit_count + 1; 
            shift <= { shift[30:0], 1'b0 };

            if (bit_count == 0) begin
                ram_addr <= ram_addr + 1;
                case (ram_addr)
                    0   :   shift <= tx_data;
                    1   :   shift <= tx_data;
                    2   :   shift <= tx_data;
                    3   :   shift <= tx_data;
                    4   :   shift <= tx_data;
                    5   :   shift <= tx_data;
                    6   :   shift <= tx_data;
                    7   :   shift <= tx_data;
                    8   :   shift <= tx_data;
                    9   :   shift <= tx_data;
                    10  :   shift <= tx_data;
                    11  :   shift <= tx_data;
                    12  :   shift <= 32'h0; // reset frame
                    13  :   shift <= 32'hffff_ffff; // end frame
                    14  :   ; // no clock during this frame
                    15  :   shift <= 32'h0; // start frame
                endcase
            end
        end

        if (enabled && (ram_addr != 14)) begin
            if (led_en) begin
                led_ck <= 0;
            end
            if (led_half) begin
                led_ck <= 1;
            end
        end

    end

    assign led_data = enabled ? shift[31] : 0;

endmodule


