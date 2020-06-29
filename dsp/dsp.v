
module addr_adder(
    input wire ck,
    input wire [FRAME_W-1:0] frame,
    input wire [FRAME_W-1:0] offset,
    input wire [CHAN_W-1:0] chan,
    output reg [(FRAME_W+CHAN_W)-1:0] addr
);

    parameter FRAME_W = 4;
    parameter CHAN_W = 3;

    reg [(FRAME_W+CHAN_W)-1:0] hold;

    always @(posedge ck) begin
        hold <= { chan, frame + offset };
    end

    always @(negedge ck) begin
        addr <= hold;
    end

endmodule

   /*
    *
    */

module multiplier(
    input wire ck,
    input  wire signed [15:0] a,
    input wire signed [15:0] b,
    output reg signed [31:0] out
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
    input wire signed add,
    input wire [31:0] data,
    output reg signed [(OUT_W-1):0] out
);

    parameter OUT_W = 40;

    initial out = 0;

    wire [(OUT_W-33):0] top;
    wire [(OUT_W-1):0] in;

    assign top = {(OUT_W-32){ $signed(data[31]) }};

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

module shifter(
    input wire ck,
    input wire [2:0] shift,
    input wire [(ACC_W-1):0] acc,
    output reg [15:0] out
);

    parameter ACC_W = 40;

    always @(negedge ck) begin
        case (shift)
            0   :   out <= acc[15:0];
            1   :   out <= acc[19:4];
            2   :   out <= acc[23:8];
            3   :   out <= acc[27:12];
            4   :   out <= acc[31:16];
            5   :   out <= acc[35:20];
            6   :   out <= acc[39:24];
            7   :   out <= 0;
        endcase
    end

endmodule

   /*
    *
    */

module pipe(
    input wire ck, 
    input wire in, 
    output reg out
);

    parameter LEN=0;
    parameter DEF=0;

    reg [(LEN-1):0] delay = DEF;
    initial out = DEF;

    always @(posedge ck) begin
        delay <= (delay << 1) + in;
        out <= delay[LEN-1];
    end

endmodule

   /*
    *
    */

module sequencer(
    input wire ck,
    input wire rst,
    input wire [(FRAME_W-1):0] frame,
    output reg [(CODE_W-1):0] coef_addr,
    input wire [31:0] coef_data,
    output reg [(AUDIO_W-1):0] audio_addr,
    input wire [15:0] audio_in,
    output reg [3:0] out_addr,
    output reg [15:0] out_audio,
    output reg out_we,
    output reg done
);
    parameter CHAN_W = 3;
    parameter FRAME_W = 4;
    parameter CODE_W = 8;
    parameter AUDIO_W = 9;
    parameter ACC_W = 40;

    //  Program Counter

    initial coef_addr = -1;

    reg [31:0] code;

    reg done_req = 0;
    reg done_0 = 0;

    always @(negedge ck) begin
        done_0 <= done_req;
        done <= done_0;
    end

/* verilator lint_off UNUSED */
    reg error = 0;
/* verilator lint_on UNUSED */

    wire [6:0] op_code;
    wire [(FRAME_W-1):0] offset;
    wire [(CHAN_W-1):0] chan;
    wire [15:0] gain;

    // decode the command
    // OP_CODE,CHAN,OFFSET,GAIN
    assign gain    = code[15:0];
    assign chan    = code[16+(CHAN_W-1):16];
    assign offset  = code[16+(CHAN_W+FRAME_W-1):16+(CHAN_W)];
    assign op_code = code[31:16+(CHAN_W+FRAME_W)];

    wire seq_en;
    pipe #(.LEN(1), .DEF(0)) reset_pipe(.ck(ck), .in(rst), .out(seq_en));

    always @(negedge ck) begin

        if (!rst) begin
            coef_addr <= 0;
            done_req <= 0;
            error <= 0;
        end else begin
            if (!done_req)
                coef_addr <= coef_addr + 1;
        end

        code <= coef_data;

        // Decode the instructions
        if (seq_en && !done_req) begin
            case (op_code)
                7'h00   : begin write_req <= 0; done_req <= 1; end // halt
                7'h40   : begin write_req <= 0; acc_rst <= 1; end // MAC 
                7'h41   : begin write_req <= 0; acc_rst <= 0; end // MAC, Zero the ACC first
                7'h42   : begin write_req <= 1; acc_rst <= 1; end //shift / save / output the result
                default : begin write_req <= 0; error <= 1; done_req <= 1; acc_rst <= 0; end
            endcase
        end
        
    end

    reg [15:0] gain_pipe_0 = 0;
    reg [15:0] gain_pipe_1 = 0;

    always @(negedge ck) begin
        gain_pipe_0 <= gain;
        gain_pipe_1 <= gain_pipe_0;
    end

    reg [15:0] audio_in_latch;

    always @(negedge ck) begin
        audio_in_latch <= audio_in;
    end

    wire [31:0] mul_out;

    multiplier mul(.ck(ck), .a(gain_pipe_1), .b(audio_in_latch), .out(mul_out));

    wire [(ACC_W-1):0] acc_out;
    reg acc_rst;

    accumulator #(.OUT_W(ACC_W)) acc(.ck(!ck), .en(1'b1), .rst(acc_rst), .add(1'b1), .data(mul_out), .out(acc_out));

    /* verilator lint_off UNUSED */
    wire [15:0] data_out;
    /* verilator lint_on UNUSED */

    reg [2:0] offset_0 = 0;
    reg [2:0] offset_1 = 0;

    always @(posedge ck) begin
        offset_0 <= offset[2:0];
        offset_1 <= offset_0;
    end

    shifter sh (.ck(!ck), .shift(offset_1), .acc(acc_out), .out(data_out));

    addr_adder #(.FRAME_W(FRAME_W), .CHAN_W(CHAN_W)) 
            addr_add (.ck(ck), .frame(frame), .offset(offset), .chan(chan), .addr(audio_addr));

    reg write_req = 0;

    reg out_we_0 = 0;
    initial out_we = 0;

    always @(negedge ck) begin
        if (!rst) begin
            out_we <= 0;
            out_we_0 <= 0;
        end else begin
            out_we_0 <= write_req;
            out_we <= out_we_0;
        end
    end

    reg [3:0] out_addr_0 = 0;
    reg [3:0] out_addr_1 = 0;

    always @(negedge ck) begin
        out_addr_0 <= chan;
        out_addr_1 <= out_addr_0;
        out_addr <= out_we_0 ? out_addr_1 : 0;

        out_audio <= out_we_0 ? data_out : 0;
    end

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

    /* verilator lint_off UNUSED */
    wire [3:0] out_wr_addr;
    wire [15:0] out_audio;
    wire out_we;
    reg [(FRAME_W-1):0] frame = 4;
    wire done;
    /* verilator lint_on UNUSED */

    sequencer #(.CHAN_W(CHAN_W), .FRAME_W(FRAME_W)) seq (
            .ck(ck), .rst(rst), .frame(frame),
            .coef_addr(coef_raddr), .coef_data(coef_rdata), 
            .audio_addr(audio_raddr), .audio_in(audio_rdata),
            .out_addr(out_wr_addr), .out_audio(out_audio), .out_we(out_we),
            .done(done));

    //  Assign io signals

    assign P1A1 = ck;
    assign P1A2 = | coef_rdata;
    assign P1A3 = rst;

endmodule

