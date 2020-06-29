
module addr_adder(
    input wire ck,
    input wire [FRAME_W-1:0] frame,
    input wire [FRAME_W-1:0] offset,
    input wire [CHAN_W-1:0] chan,
    output reg [(FRAME_W+CHAN_W)-1:0] addr
);

    parameter FRAME_W = 4;
    parameter CHAN_W = 3;

    always @(posedge ck) begin
        addr <= { chan, frame + offset };
    end

endmodule

   /*
    *
    */

module multiplier(
    input wire ck,
    input wire [15:0] a,
    input wire [15:0] b,
    output reg [31:0] out
);

    always @(posedge ck) begin
        out <= a * b;
    end

endmodule

   /*
    *
    */

module accumulator(
    input wire ck,
    input wire en,
    input wire rst,
    input wire add,
    input wire [31:0] data,
    output reg [(OUT_W-1):0] out
);

    parameter OUT_W = 40;

    initial out = 0;

    wire [(OUT_W-33):0] top = 0;
    wire [(OUT_W-1):0] in;

    assign in = { top, data };

    always @(posedge ck) begin
        if (!rst)
            out <= 0;
        else if (en) begin
            if (add)
                out <= out + in;
            else
                out <= out - in;
        end
    end

endmodule

   /*
    *
    */

module sequencer(
    input wire ck,
    input wire rst,
    output reg [(CODE_W-1):0] coef_addr,
    input wire [31:0] coef_data,
    output reg [(AUDIO_W-1):0] audio_addr,
    input wire [15:0] audio_in
);

    parameter CHAN_W = 3;
    parameter FRAME_W = 4;
    parameter CODE_W = 8;
    parameter AUDIO_W = 9;
    parameter ACC_W = 40;

    //  Program Counter

    initial coef_addr = -1;

    reg [31:0] code;

    reg done = 0;
/* verilator lint_off UNUSED */
    reg error = 0;
/* verilator lint_on UNUSED */

    wire [6:0] op_code;
    wire [(FRAME_W-1):0] offset;
    wire [(CHAN_W-1):0] chan;
    wire [15:0] gain;

    // decode the command
    // OP_CODE,CHAN,OFFSET,GAIN
    assign gain = code[15:0];
    assign chan = code[16+(CHAN_W-1):16];
    assign offset = code[16+(CHAN_W+FRAME_W-1):16+(CHAN_W)];
    assign op_code = code[31:16+(CHAN_W+FRAME_W)];

    reg [1:0] rst_pipe = 0;
    reg [15:0] gain_pipe_0 = 0;
    reg [15:0] gain_pipe_1 = 0;

    always @(posedge ck) begin
        gain_pipe_0 <= gain;
        gain_pipe_1 <= gain_pipe_0;
    end

    wire [31:0] mul_out;

    multiplier mul(.ck(!ck), .a(gain_pipe_1), .b(audio_in), .out(mul_out));

    /* verilator lint_off UNUSED */
    wire [(ACC_W-1):0] acc_out;
    /* verilator lint_on UNUSED */
    reg acc_en = 1; // TODO
    reg acc_rst;
    reg acc_add = 1; // TODO

    accumulator #(.OUT_W(ACC_W)) acc(.ck(ck), .en(acc_en), .rst(acc_rst), .add(acc_add), .data(mul_out), .out(acc_out));

    always @(negedge ck) begin

        rst_pipe <= (rst_pipe << 1) + rst;

        if (!rst) begin
            coef_addr <= 0;
            done <= 0;
            error <= 0;
        end else begin
            if (!done)
                coef_addr <= coef_addr + 1;
        end

        code <= coef_data;

        // Decode the instructions
        if (rst_pipe[1]) begin
            case (op_code)
                7'h00 : done <= 1; // halt
                7'h40 : acc_rst <= 1; // MAC 
                7'h41 : acc_rst <= 0; // MAC, Zero the ACC first
                7'h42 : acc_rst <= 1; // TODO : shift / output the result
                default : begin error <= 1; done <= 1; end
            endcase
        end
        
    end

    reg [(FRAME_W-1):0] frame = 0;

    addr_adder #(.FRAME_W(FRAME_W), .CHAN_W(CHAN_W)) 
            addr_add (.ck(ck), .frame(frame), .offset(offset), .chan(chan), .addr(audio_addr));

endmodule

    /*
    *   Top module
    */

module top (input wire CLK, output wire P1A1, output wire P1A2, output wire P1A3);

    wire ck;
    assign ck = CLK;

    // Reset line
    reg rst = 0;

    always @(posedge ck) begin
        rst <= 1;
    end

    //  Drive the engine

    localparam CHANNELS = 16;
    localparam FRAMES = 32;
    localparam CODE = 256;
    localparam CHAN_W = $clog2(CHANNELS);
    localparam FRAME_W = $clog2(FRAMES);
    localparam CODE_W = $clog2(CODE);
    localparam AUDIO = CHANNELS * FRAMES;
    localparam AUDIO_W = $clog2(AUDIO);

    // Coef / Program DP RAM
    reg coef_we = 0;
    reg [31:0] coef_wdata = 0;
    reg [(CODE_W-1):0] coef_waddr = 0;
    wire [31:0] coef_rdata;
    wire [(CODE_W-1):0] coef_raddr;

    dpram #(.BITS(32), .SIZE(CODE), .FNAME("coef.data"))
        coef (.ck(ck), 
            .we(coef_we), .waddr(coef_waddr), .wdata(coef_wdata),
            .re(1'h1), .raddr(coef_raddr), .rdata(coef_rdata));

    // Audio Input DP RAM

    reg audio_we = 0;
    reg [15:0] audio_wdata = 0;
    reg [(AUDIO_W-1):0] audio_waddr = 0;
    wire [15:0] audio_rdata;
    wire [(AUDIO_W-1):0] audio_raddr;

    dpram #(.BITS(16), .SIZE(AUDIO), .FNAME("audio.data")) 
        audio_in (.ck(ck), 
            .we(audio_we), .waddr(audio_waddr), .wdata(audio_wdata),
            .re(1'h1), .raddr(audio_raddr), .rdata(audio_rdata));

    // Sequencer

    sequencer #(.CHAN_W(CHAN_W), .FRAME_W(FRAME_W)) seq (.ck(ck), .rst(rst),
            .coef_addr(coef_raddr), .coef_data(coef_rdata), 
            .audio_addr(audio_raddr), .audio_in(audio_rdata));

    //  Assign io signals

    assign P1A1 = ck;
    assign P1A2 = | coef_rdata;
    assign P1A3 = rst;

endmodule

