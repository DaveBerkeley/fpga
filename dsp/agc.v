
`default_nettype none

module agc
#(parameter IN_W=24, OUT_W=16, CHANS=8, LEVEL_W=$clog2(IN_W), CHAN_W=$clog2(CHANS))
(
    input wire ck,
    input wire en,
    output wire [CHAN_W-1:0] src_addr,
    input wire signed [IN_W-1:0] in_data,
    output wire [LEVEL_W-1:0] level,
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
    wire [OUT_W-1:0] gain_out;
    wire [CHAN_W-1:0] gain_addr;
    reg gain_en = 0;
    reg gain_wait = 0;

    wire find_gain;
    assign find_gain = gain_en | !gain_ready;

    wire busy;
    assign busy = find_max | find_normal | find_level | find_gain;

    gain #(.IN_W(IN_W), .OUT_W(OUT_W), .CHAN_W(CHAN_W))
    gain (
        .ck(ck),
        .en(gain_en),
        .addr(gain_addr),
        .in_data(in_data),
        .out(gain_out),
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
    assign src_addr = (find_max ? address : 0) | gain_addr;

endmodule

module gain
#(parameter IN_W=24, OUT_W=16, CHAN_W=3)
(
    input wire ck,
    input wire en,
    output reg [CHAN_W-1:0] addr,
    input wire signed [IN_W-1:0] in_data,
    output reg [OUT_W-1:0] out,
    output reg done
);

    initial done = 0;
    initial out = 0;

    assign addr = 0;

    reg delay = 0;

    always @(posedge ck) begin

        if (en) begin
            done <= 0;
        end

        delay <= en;

        if (delay) begin
            done <= 1;
        end

    end

endmodule

