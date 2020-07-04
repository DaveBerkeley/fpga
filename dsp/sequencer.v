
   /*
    *
    */

module addr_adder(
    input wire ck,
    input wire [FRAME_W-1:0] frame,
    input wire [FRAME_W-1:0] offset,
    input wire [CHAN_W-1:0] chan,
    output reg [(FRAME_W+CHAN_W)-1:0] addr
);

    parameter FRAME_W = 4;
    parameter CHAN_W = 3;

    reg [(FRAME_W+CHAN_W)-1:0] addr_0;

    always @(posedge ck) begin
        addr_0 <= { chan, frame + offset };
    end

    always @(negedge ck) begin
        addr <= addr_0;
    end

endmodule

   /*
    *
    */

module multiplier(
    input wire ck,
    input  wire /*signed*/ [15:0] a,
    input wire /*signed*/ [15:0] b,
    output reg /*signed*/ [31:0] out
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

    always @(posedge ck) begin
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

module sequencer(
    input wire ck,
    input wire rst,
    input wire [(FRAME_W-1):0] frame,
    output reg [(CODE_W-1):0] coef_addr,
    input wire [31:0] coef_data,
    output wire [(AUDIO_W-1):0] audio_raddr,
    input wire [15:0] audio_in,
    output reg [3:0] out_addr,
    output reg [15:0] out_audio,
    output reg out_we,
    output reg done,
    output reg error,
    input wire [2:0] test_in,
    output reg [7:0] test_out,
    output reg [31:0] capture_out
);
    parameter CHAN_W = 3;
    parameter FRAME_W = 4;
    parameter CODE_W = 8;
    parameter AUDIO_W = 9;
    parameter ACC_W = 40;

    // Align the reset to the -ve edge
    // to ensure the pipeline operates correctly
    reg reset = 0;

    always @(negedge ck) begin
        reset <= rst;
    end

    initial done = 0;

    //  Program Counter

    initial coef_addr = -1;
    initial error = 0;

    wire [(AUDIO_W-1):0] audio_addr;
    assign audio_raddr = done ? 0 : audio_addr;

    reg [31:0] code;

    reg done_req = 0;
    reg done_0 = 0;

    always @(negedge ck) begin
        done_0 <= done_req & rst;
        done <= done_0 & rst;
    end

    reg [2:0] capture = 0;
    initial capture_out = 0;

    wire [6:0] op_code;
    wire [(FRAME_W-1):0] offset;
    wire [(CHAN_W-1):0] chan;
    wire [15:0] gain;

    // decode the command
    // OP_CODE(7),CHAN(4),OFFSET(5),GAIN(16)
    assign gain    = code[15:0];
    assign chan    = code[16+(CHAN_W-1):16];
    assign offset  = code[16+(CHAN_W+FRAME_W-1):16+(CHAN_W)];
    assign op_code = code[31:16+(CHAN_W+FRAME_W)];

    reg noop = 0;
    reg noop_0 = 0;
    reg noop_1 = 0;

    always @(negedge ck) begin
        noop_0 <= noop;
    end
    always @(posedge ck) begin
        noop_1 <= noop_0;
    end

    reg [2:0] capture_match = 0;

    always @(negedge ck) begin

        if (!reset) begin
            coef_addr <= 0;
            done_req <= 0;
            error <= 0;
        end else begin
            // Increment Program Counter
            if (!done_req) begin
                coef_addr <= coef_addr + 1;
            end
        end

        // Save the current instruction
        code <= coef_data;

        if (write_req)
            write_req <= 0;
        if (noop)
            noop <= 0;
        if (capture != 0)
            capture <= capture - 1;

        // Decode the instructions
        if (reset && !done_req) begin
            casez (op_code)
                7'b000_0000 : begin done_req <= 1; end  // halt
                7'b001_0??? : begin capture <= 5; capture_match <= op_code[2:0]; end // Capture
                7'b100_0000 : begin acc_rst <= 1; end   // MAC 
                7'b100_0001 : begin acc_rst <= 0; end   // MAC, Zero the ACC first
                7'b100_0010 : begin write_req <= 1; acc_rst <= 1; end //shift / save / output the result
                7'b111_1111 : noop <= 1; // No-op
                default     : begin error <= 1; done_req <= 1; acc_rst <= 0; end
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

    reg add = 1;
    accumulator #(.OUT_W(ACC_W)) acc(.ck(!ck), .en(!noop_1), .rst(acc_rst), .add(add), .data(mul_out), .out(acc_out));

    /* verilator lint_off UNUSED */
    wire [15:0] data_out;
    /* verilator lint_on UNUSED */

    reg [2:0] offset_0 = 0;
    reg [2:0] offset_1 = 0;

    always @(posedge ck) begin
        offset_0 <= offset[2:0];
        offset_1 <= offset_0;
    end

    shifter sh (.ck(ck), .shift(offset_1), .acc(acc_out), .out(data_out));

    addr_adder #(.FRAME_W(FRAME_W), .CHAN_W(CHAN_W)) 
            addr_add (.ck(ck), .frame(frame), .offset(offset), .chan(chan), .addr(audio_addr));

    reg write_req = 0;

    reg out_we_0 = 0;
    initial out_we = 0;

    always @(negedge ck) begin
        if (!reset) begin
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

    always @(posedge ck) begin

        // capture_match is the requested trace
        // capture is the time slot, counting down from 5
        if ((capture_match == 0) && (capture == 3))
            capture_out <= { gain_pipe_1, audio_in_latch }; // multiplier in
        if ((capture_match == 1) && (capture == 2))
            capture_out <= mul_out; // multiplier out
        if ((capture_match == 2) && (capture == 2))
            capture_out <= acc_out[31:0]; // accumulator out
        if ((capture_match == 3) && (capture == 1))
            capture_out <= { 13'h0, offset_1, data_out }; // shifter out
        if ((capture_match == 4) && (capture == 1))
            capture_out <= { 12'h0, out_addr, out_audio };
        if ((capture_match == 5) && (capture == 4))
            capture_out <= { audio_in, 7'h0, audio_addr };
        if ((capture_match == 6) && (capture == 5))
            capture_out <= code;
        if ((capture_match == 7) && (capture == 5))
            capture_out <= { 11'h0, frame, 7'h0, offset, chan };

    end

    function [7:0] test_src(input [2:0] select);
        case (select)
            0 : test_src = { 3'b0, add, out_we, out_we_0, write_req, acc_rst };
            1 : test_src = gain[7:0];
            2 : test_src = gain_pipe_0[7:0];
            3 : test_src = gain_pipe_1[7:0];
            4 : test_src = audio_in[7:0];
            5 : test_src = audio_in_latch[7:0];
            6 : test_src = audio_raddr[7:0];
            7 : test_src = { 3'b0, noop_1, noop_0, noop, done_0, done_req };
        endcase
    endfunction

    always @(posedge ck) begin
        test_out <= test_src(test_in);
    end

endmodule

