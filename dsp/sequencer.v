
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
    output reg [31:0] capture_out
);
    parameter CHAN_W = 4;
    parameter FRAME_W = 4;
    parameter CODE_W = 8;
    parameter AUDIO_W = 9;
    parameter ACC_W = 40;

    // Align the reset to the +ve edge
    // to ensure the pipeline operates correctly
    reg reset = 1;

    always @(posedge ck) begin
        reset <= !rst;
    end

    initial begin 
        coef_addr = 0;
        error = 1;
        out_we = 0;
        capture_out = 0;
    end

    // Pipeline t0
    // Program Counter : fetch the opcodes / coefficients
 
    always @(posedge ck) begin
        if (reset && !done_req)
            coef_addr <= coef_addr + 1;
        else
            coef_addr <= 0;
    end

    // Pipeline t1
    // Latch the op-code, offset, chan and gain

    localparam OP_W = 16 - (CHAN_W + FRAME_W);

    reg [(OP_W-1):0] op_code;
    reg [(FRAME_W-1):0] offset;
    reg [(CHAN_W-1):0] chan;
    reg [15:0] gain;

    always @(posedge ck) begin
        if (reset && !done_req && (coef_addr != 0)) begin
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
    reg acc_add_req = 0;    // set if gain is +ve

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

    // Save the address used to fetch the current audio fetch
    reg [(AUDIO_W-1):0] audio_raddr_0;

    always @(posedge ck) begin
        audio_raddr_0 <= audio_raddr;
    end

    wire [(16-AUDIO_W-1):0] pad;
    assign pad = 0;

    task capture(input [3:0] code);
        noop();
        case (code)
            0 : capture_out <= coef_data; // the next instructon
            1 : capture_out <= { audio_in, pad, audio_raddr_0 }; 
            2 : capture_out <= { gain_2, audio }; // multiplier in
            3 : capture_out <= mul_out; // multiplier out

            5 : capture_out <= acc_out[31:0]; // accumulator out
            6 : capture_out <= { 12'h0, out_addr, out_audio };
            7 : capture_out <= { 32'h12345678 };
        endcase
    endtask

    localparam OP_NOOP      = 5'b00000;
    localparam OP_CAPTURE   = 5'b00001;
    localparam OP_SAVE      = 5'b00010;
    localparam OP_MAC       = 5'b01000;
    localparam OP_MACZ      = 5'b01001;
    localparam OP_MACN      = 5'b01010;
    localparam OP_MACNZ     = 5'b01011;
    localparam OP_HALT      = 5'b01111;

    // Decode the instructions
    always @(posedge ck) begin
        if (reset) begin
            case (op_code)
                OP_NOOP     : noop();
                OP_CAPTURE  : capture(offset[3:0]);
                OP_MAC      : mac(0, 1);
                OP_MACN     : mac(0, 0);
                OP_MACZ     : mac(1, 1);
                OP_MACNZ    : mac(1, 0);
                OP_SAVE     : save();
                OP_HALT     : halt();
                default     : err();
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

    always @(posedge ck) begin
        gain_0 <= gain;
    end

    // Pipeline t3

    // Sign adjust for the multiplier and accumulator stages
    //
    // If the audio is -ve, make it signed
    // But use subtract at the accumulator stage

    reg [15:0] gain_1;
    reg [15:0] gain_2;

    always @(posedge ck) begin
        gain_1 <= gain_0;
        gain_2 <= gain_1;
    end

    // test top bit of audio for -ve value
    wire neg_audio;
    assign neg_audio = audio_in[15];

    wire [15:0] audio;

    twos_complement #(.WIDTH(16)) neg(.ck(ck), .inv(neg_audio), .in(audio_in), .out(audio));

    // pipeline the sign change to apply at the accumulator stage
    reg negative = 0;

    always @(posedge ck) begin
        negative <= neg_audio;
    end

    // Pipeline t4
    // Multiply normalised audio signal by gain

    wire [31:0] mul_out;

    multiplier mul(.ck(ck), .a(gain_2), .b(audio), .out(mul_out));

    // Pipeline t5
    // Acumulator Stage

    wire signed [(ACC_W-1):0] acc_out;

    wire acc_reset, acc_en;
    pipe #(.LENGTH(3)) pipe_acc_reset (.ck(ck), .rst(reset), .in(acc_rst_req), .out(acc_reset));
    pipe #(.LENGTH(3)) pipe_acc_en    (.ck(ck), .rst(reset), .in(acc_en_req), .out(acc_en));

    reg acc_add_0 = 0;
    reg acc_add_1 = 0;
    reg acc_add = 0;
    always @(posedge ck) begin
        acc_add_0 <= acc_add_req;
        // subtract if the audio is -ve
        acc_add_1 <= acc_add_0;
        acc_add <= acc_add_1 ^ negative;
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
    reg [(FRAME_W-1):0] shift_3 = 0;

    always @(posedge ck) begin
        shift_0 <= offset;
        shift_1 <= shift_0;
        shift_2 <= shift_1;
        shift_3 <= shift_2;
    end

    wire [15:0] shift_out;

    wire shift_en;
    pipe #(.LENGTH(3)) pipe_shift_en (.ck(ck), .rst(reset), .in(out_en_req), .out(shift_en));
 
    shifter #(.SHIFT_W(FRAME_W)) shift_data (.ck(ck), .en(shift_en), .shift(shift_3), .in(acc_out), .out(shift_out));

    // Pipeline t7
    // Write output
    // Takes data from the shifter and writes to address derived from 'gain' field

    always @(posedge ck) begin
        out_we <= shift_en;
    end

    reg [3:0] out_addr_0;
    reg [3:0] out_addr_1;
    reg [3:0] out_addr_2;

    always @(posedge ck) begin
        out_addr_0 <= gain_1[3:0];
        out_addr_1 <= out_addr_0;
        out_addr_2 <= out_addr_1;
    end

    assign out_audio = out_we ? shift_out : 0;
    assign out_addr = out_we ? out_addr_2[3:0] : 0;

    // Sequence ended. Assert 'done'

    pipe #(.LENGTH(3)) pipe_done (.ck(ck), .rst(reset), .in(done_req), .out(done));

endmodule

