
   /*
    *
    */

module pipe(input wire ck, input wire rst, input wire in, output wire out);

    parameter LENGTH=1;

    reg [(LENGTH-1):0] delay;

    /* verilator lint_off WIDTH */
    always @(negedge ck) begin
        if (rst)
            delay <= (delay << 1) | in;
        else
            delay <= 0;
    end
    /* verilator lint_on WIDTH */

    assign out = delay[LENGTH-1];

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
    output reg [31:0] capture_out,
    output wire [7:0] test
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
        capture_out = 0;
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
    reg acc_add_req = 0;        // set if gain is -ve

    task noop;
        acc_en_req <= 0;
        out_en_req <= 0;
        acc_rst_req <= 0;
        acc_add_req <= 0;
    endtask

    task mac(input zero, input add);
        acc_en_req <= 1;
        acc_rst_req <= zero;
        acc_add_req <= add;
        out_en_req <= 0;
    endtask

    task halt;
        noop();
        done_req <= 1;
    endtask

    task save;
        acc_en_req <= 0;
        acc_rst_req <= 0;
        acc_add_req <= 0;
        out_en_req <= 1;
    endtask

    task err;
        error <= 1;
    endtask

    task capture(input [3:0] code);
        noop();
        case (code)
            0 : capture_out <= coef_data; // the next instructon
            1 : capture_out <= { audio_in, 7'h0, audio_raddr }; 
            2 : capture_out <= { gain_1, audio }; // multiplier in
            3 : capture_out <= mul_out; // multiplier out

            5 : capture_out <= acc_out[31:0]; // accumulator out
            6 : capture_out <= { 12'h0, out_addr, out_audio };
            7 : capture_out <= { 32'h12345678 };
        endcase
    endtask

    // Decode the instructions
    always @(negedge ck) begin
        if (reset) begin
            casez (op_code)
                7'b000_0000 : noop();       // No-op
                7'b001_???? : capture(op_code[3:0]); // Capture
                7'b100_0000 : mac(0, 1);    // MAC 
                7'b100_0001 : mac(0, 0);    // MACN
                7'b100_0010 : mac(1, 1);    // MACZ
                7'b100_0011 : mac(1, 0);    // MACNZ
                7'b101_0000 : save();       // shift / save / output the result
                7'b111_1111 : halt();       // halt
                default     : err();        // Error
            endcase
        end else begin
            noop();
            error <= 0;
            done_req <= 0;
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

    multiplier mul(.ck(!ck), .a(gain_1), .b(audio), .out(mul_out));

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
        acc_add_0 <= acc_add_req;
        // subtract if the audio is -ve
        acc_add <= acc_add_0 ^ negative;
    end

    wire [31:0] acc_in;
    assign acc_in = mul_out;

    accumulator #(.OUT_W(ACC_W)) acc(.ck(ck), .en(acc_en), .rst(acc_reset), 
        .add(acc_add), .in(acc_in), .out(acc_out));

    // Pipeline t6
    // Shift the 40-bit accumulator result into 16-bits

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

    // Sequence ended. Assert 'done'

    pipe #(.LENGTH(3)) pipe_done (.ck(ck), .rst(reset), .in(done_req), .out(done));

    assign test = { ck, error, done, reset, out_we, acc_reset, acc_en, acc_add };
 
endmodule

