
   /*
    *
    */

module pipe(input wire ck, input wire rst, input wire in, output wire out);

    parameter LENGTH=1;

    reg [(LENGTH-1):0] delay;

    always @(negedge ck) begin
        if (rst)
            delay <= { in, delay[(LENGTH-1):1] };
        else
            delay <= 0;
    end

    assign out = delay[0];

endmodule

   /*
    *
    */

module twos_complement(input wire ck, input wire [15:0] in, output reg [15:0] out);

    initial out = 0;

    always @(negedge ck) begin
        out <= (~in) + 1'b1;
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
    output reg error,
    output wire done,
    output wire [3:0] out_addr,
    output wire [15:0] out_audio,
    output reg out_we,
    /* verilator lint_off UNUSED */
    input wire [2:0] test_in,
    output reg [7:0] test_out,
    output reg [31:0] capture_out
    /* verilator lint_on UNUSED */
);
    parameter CHAN_W = 4;
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

    initial begin 
        coef_addr = 0;
        error = 0;
        out_we = 0;
        test_out = 0;
        capture_out = 0;
    end

    always @(negedge ck) begin
        if (!reset) begin
            error <= 0;
        end
    end

    // Pipeline t0
    // Program Counter : fetch the opcodes / coefficients
 
    always @(negedge ck) begin
        if (reset)
            coef_addr <= coef_addr + 1;
        else
            coef_addr <= 0;
    end

    // Pipeline t1
    // Latch the op-code, offset, chan and gain

    reg [6:0] op_code;
    reg [(FRAME_W-1):0] offset;
    reg [(CHAN_W-1):0] chan;
    reg [15:0] gain;

    always @(negedge ck) begin
        if (reset & !done_req) begin
            gain    <= coef_data[15:0];
            chan    <= coef_data[16+(CHAN_W-1):16];
            offset  <= coef_data[16+(CHAN_W+FRAME_W-1):16+(CHAN_W)];
            op_code <= coef_data[31:16+(CHAN_W+FRAME_W)];
        end else begin
            op_code <= 0;
        end
    end

    // Pipeline t2

    // Instruction Decode

    reg acc_rst_req = 0;    // reset the accumulator
    reg done_req = 0;       // sequence finished
    reg acc_en_req = 0;     // enable accumulator
    reg out_en_req = 0;     // enable accumulator
    reg add_req = 0;        // set if gain is -ve

    task mac(input [1:0] code);
        acc_en_req <= 1;
        acc_rst_req <= code[0];
        add_req <= !code[1];
        out_en_req <= 0;
    endtask

    task halt;
        acc_en_req <= 0;
        acc_rst_req <= 0;
        out_en_req <= 0;
        add_req <= 0;
        done_req <= 1;
    endtask

    task save;
        acc_en_req <= 0;
        acc_rst_req <= 0;
        add_req <= 0;
        out_en_req <= 1;
    endtask

    task noop;
        acc_en_req <= 0;
        out_en_req <= 0;
        acc_rst_req <= 0;
        add_req <= 0;
    endtask

    task err;
        error <= 1;
    endtask

    // Decode the instructions
    always @(negedge ck) begin
        if (reset) begin
            casez (op_code)
                7'b111_1111 : halt();           // halt
                //7'b001_0??? : ; // Capture
                7'b100_00?? : mac(op_code[1:0]);// MAC 
                7'b101_0000 : save();           // shift / save / output the result
                7'b000_0000 : noop();           // No-op
                default     : err();            // Error
            endcase
        end else begin
            error <= 0;
            acc_en_req <= 0;
            acc_rst_req <= 0;
            out_en_req <= 0;
            done_req <= 0;
            add_req <= 0;
        end
    end
 
    // Calculate the input audio addr to fetch the next sample from

    addr_adder#(.FRAME_W(FRAME_W), .CHAN_W(CHAN_W)) 
        adder(.ck(ck), .frame(frame), .offset(offset), .chan(chan), .addr(audio_raddr)); 

    // Align the gain to feed the multiplier

    reg [15:0] gain_0;

    always @(negedge ck) begin
        gain_0 <= gain;
    end

    // Pipeline t3

    // Sign adjust for the multiplier and accumulator stages
    //
    // If the audio is -ve, make it signed
    // But use subtract at the accumulator stage

    reg negative = 0;

    // test top bit of audio for -ve value
    always @(negedge ck) begin
        negative <= audio_in[15];
    end

    reg [15:0] gain_1;
    reg [15:0] audio_0;

    always @(negedge ck) begin
        gain_1 <= gain_0;
        audio_0 <= audio_in;
    end

    wire [15:0] neg_audio;

    twos_complement neg(.ck(ck), .in(audio_in), .out(neg_audio));

    wire [15:0] audio;

    assign audio = negative ? neg_audio : audio_0;

    // Pipeline t4
    // Multiply audio signal by gain

    wire [31:0] mul_out;

    multiplier mul(.ck(ck), .a(gain_1), .b(audio), .out(mul_out));

    // Pipeline t5
    // Acumulator Stage

    /* verilator lint_off UNUSED */
    wire signed [(ACC_W-1):0] acc_out;
    /* verilator lint_on UNUSED */

    wire acc_reset, acc_en;
    pipe #(.LENGTH(2)) pipe_acc_reset (.ck(ck), .rst(reset), .in(acc_rst_req), .out(acc_reset));
    pipe #(.LENGTH(2)) pipe_acc_en    (.ck(ck), .rst(reset), .in(acc_en_req), .out(acc_en));

    reg acc_add_0 = 0;
    reg acc_add = 0;
    always @(negedge ck) begin
        acc_add_0 <= add_req;
        acc_add <= acc_add_0 ^ negative;
    end

    accumulator #(.OUT_W(ACC_W)) acc(.ck(ck), .en(acc_en), .rst(acc_reset), 
        .add(acc_add), .data(mul_out), .out(acc_out));

    // Pipeline t6
    // Shift the result into 16-bits

    // TODO : shift is delayed offset
    reg [(FRAME_W-1):0] shift_0 = 0;
    reg [(FRAME_W-1):0] shift_1 = 0;
    reg [(FRAME_W-1):0] shift_2 = 0;

    always @(negedge ck) begin
        shift_0 <= offset;
        shift_1 <= shift_0;
        shift_2 <= shift_1;
    end

    wire [15:0] shift_out;

    wire shift_en;
    pipe #(.LENGTH(2)) pipe_shift_en (.ck(ck), .rst(reset), .in(out_en_req), .out(shift_en));
 
    shifter shift_data (.ck(ck), .en(shift_en), .shift(shift_2), .in(acc_out), .out(shift_out));

    // Pipeline t7
    // Write output
    // Takes data from the shifter and writes to address derived from 'gain' field

    always @(negedge ck) begin
        out_we <= shift_en;
    end

    reg [3:0] out_addr_0;
    reg [3:0] out_addr_1;

    always @(negedge ck) begin
        out_addr_0 <= gain_1[3:0];
        out_addr_1 <= out_addr_0;
    end

    assign out_audio = out_we ? shift_out : 0;
    assign out_addr = out_we ? out_addr_1[3:0] : 0;

    // Sequence ended

    pipe #(.LENGTH(3)) pipe_done (.ck(ck), .rst(reset), .in(done_req), .out(done));

    /*

    reg [2:0] capture = 0;
    initial capture_out = 0;

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
    */

endmodule

