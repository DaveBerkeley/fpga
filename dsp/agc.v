
`default_nettype none

module agc
#(parameter IN_W=24, OUT_W=16, CHANS=8, LEVEL_W=$clog2(IN_W), CHAN_W=$clog2(CHANS))
(
    input wire ck,
    input wire en,
    output wire [CHAN_W-1:0] src_addr,
    input wire signed [IN_W-1:0] in_data,
    output wire [LEVEL_W-1:0] level,
    output wire signed [OUT_W-1:0] out,
    output wire out_we,
    output wire done
);

    wire [IN_W-1:0] normal;

    // Take signed wide input data and convert to absolute value.
    twos_complement #(.WIDTH(IN_W))
    twos_complement(
        .ck(ck),
        .inv(in_data[IN_W-1]),
        .in(in_data),
        .out(normal)
    );

    // Calculate the index of the MSB.
    // This corresponds to the required shift
    // needed to convert the eg 24-bit signal into a 16-bit one.
    wire level_ready;
    reg level_en = 0;

    level #(.IN_W(IN_W))
    level_mod (
        .ck(ck),
        .en(level_en),
        .in(max_in),
        .level(level),
        .ready(level_ready)
    );

    wire find_level;
    assign find_level = level_en | !level_ready;

    reg find_max = 0;
    reg [IN_W-1:0] max_in = 0;
    reg find_normal = 0;
    reg [1:0] address = 0;

    wire gain_ready;
    wire [CHAN_W-1:0] gain_addr;
    reg gain_en = 0;
    reg gain_wait = 0;

    wire find_gain;
    assign find_gain = gain_en | !gain_ready;

    wire busy;
    assign busy = find_max | find_normal | find_level | find_gain;

    reg [15:0] gain = 16'b111_11111_1111_1111;

    wire [CHAN_W-1:0] out_addr;

    gain #(.IN_W(IN_W), .OUT_W(OUT_W), .CHANS(CHANS))
    gain_mod (
        .ck(ck),
        .en(gain_en),
        .gain(gain),
        .addr(gain_addr),
        .in_data(in_data),
        .out_addr(out_addr),
        .out_we(out_we),
        .out_data(out),
        .done(gain_ready)
    );
 
    always @(posedge ck) begin

        if (en) begin
            // Start the sequence
            address <= 0;
            find_max <= 1;
            max_in <= 0;
        end

        find_normal <= find_max;

        if (level_en) begin
            level_en <= 0;
            gain_wait <= 1;
        end

        if (gain_wait & level_ready) begin
            gain_en <= 1;
            gain_wait <= 0;
        end

        if (gain_en) begin
            gain_en <= 0;
        end

        if (gain_ready & gain_wait) begin
            gain_wait <= 0;
        end

        if (find_normal) begin
            // find the largest abs(input)
            if (normal > max_in) begin
                max_in <= normal;
            end
            if ((address == CHANS-1) && !find_max) begin
                // Finished level acquisition.
                // Start to calculate the level
                level_en <= 1;
            end
        end

        // Step through the input channels
        // looking for the max value.
        if (find_max && !level_en) begin

            if (address != CHANS-1) begin
                // request the next input
                address <= address + 1;
            end else begin
                find_max <= 0;
            end

        end
    end

    assign done = !busy;
    assign src_addr = (find_max ? address : 0) | (find_gain ? gain_addr : 0);

endmodule

   /*
    *
    */

module shift
#(parameter IN_W=24, OUT_W=16, SHIFT=IN_W-OUT_W, SHIFT_W=$clog2(SHIFT))
(
    input wire ck,
    input wire [SHIFT_W-1:0] shift,
    input wire [IN_W-1:0] in,
    output wire [OUT_W-1:0] out
);

    wire [OUT_W-1:0] shifted;

    genvar i;

    generate

        for (i = 0; i < OUT_W; i = i + 1) begin
            assign shifted[OUT_W-(i+1)] = in[IN_W-(i+shift+1)];
        end

    endgenerate

    assign out = shifted;

endmodule

   /*
    *
    */

module gain
#(parameter GAIN_W=16, IN_W=24, OUT_W=16, CHANS=8, CHAN_W=$clog2(CHANS))
(
    input wire ck,
    input wire en,
    input wire [GAIN_W-1:0] gain,
    output reg [CHAN_W-1:0] addr,
    input wire signed [IN_W-1:0] in_data,
    output wire signed [OUT_W-1:0] out_data,
    output wire [CHAN_W-1:0] out_addr,
    output wire out_we,
    output wire done
);

    initial addr = 0;

    reg busy_start = 0;

    // Top bits of gain give the shift applied
    localparam SHIFT = IN_W - OUT_W;
    localparam SHIFT_W = $clog2(SHIFT);

    wire [SHIFT_W-1:0] shift_by;
    assign shift_by = (SHIFT-1) - gain[GAIN_W-1:GAIN_W-(SHIFT_W+1)];

    wire [IN_W-1:0] shift_in;
    wire [OUT_W-1:0] shift_out;

    assign shift_in = busy_start ? in_data : 0;

    shift #(.IN_W(IN_W), .OUT_W(OUT_W))
    shifter (
        .ck(ck),
        .shift(shift_by),
        .in(shift_in),
        .out(shift_out)
    );

    wire in_neg;
    assign in_neg = shift_out[OUT_W-1];
    wire [OUT_W-1:0] mul_abs;

    // Convert to unsigned, as 16x16 mul is unsigned
    twos_complement #(.WIDTH(OUT_W))
    inv_in(
        .ck(ck), 
        .inv(in_neg), 
        .in(shift_out), 
        .out(mul_abs)
    );

    // need gain range of 0.5 .. 1.0, so top bit always set
    wire [15:0] mul_a;
    wire [15:0] mul_b;
    assign mul_a = { gain[12:0], 3'b0 };
    assign mul_b = mul_abs;

    wire [31:0] mul_out;

    multiplier multipler(
        .ck(ck),
        .a(mul_a),
        .b(mul_b),
        .out(mul_out)
    );

    //  Now re-apply the sign of the input data
    
    wire [31:0] mul_signed;

    wire neg_out;
    pipe #(.LENGTH(2)) delay(.ck(ck), .in(in_neg), .out(neg_out));

    // Convert to unsigned, as 16x16 mul is unsigned
    twos_complement #(.WIDTH(32))
    inv_out(
        .ck(ck), 
        .inv(neg_out), 
        .in(mul_out), 
        .out(mul_signed)
    );

    always @(posedge ck) begin

        if (en) begin
            busy_start <= 1;
            addr <= 0;
        end

        if (busy_start) begin
            addr <= addr + 1;

            if (addr == (CHANS-1)) begin
                busy_start <= 0;
            end
        end 

    end

    pipe #(.LENGTH(3)) delay_addr [CHAN_W-1:0] (.ck(ck), .in(addr), .out(out_addr));

    pipe #(.LENGTH(3)) delay_done (.ck(ck), .in(busy_start), .out(out_we));

    assign out_data = mul_signed[31:16];

    wire busy;
    assign busy = busy_start | out_we;
    assign done = !busy;

endmodule

