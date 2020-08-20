
`default_nettype none

module agc
#(parameter IN_W=24, CHANS=8, OUT_W=$clog2(IN_W), CHAN_W=$clog2(CHANS))
(
    input wire ck,
    input wire en,
    output reg [CHAN_W-1:0] src_addr,
    input wire signed [IN_W-1:0] in_data,
    output wire [OUT_W-1:0] level,
    output wire done
);

    wire [IN_W-1:0] normal;

    // Take signed input data and convert to absolute value.
    twos_complement #(.WIDTH(IN_W))
    twos_complement(
        .ck(ck),
        .inv(in_data[IN_W-1]),
        .in(in_data),
        .out(normal)
    );

    // Calculate the index of the MSB.
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

    initial src_addr = 0;

    reg find_max = 0;
    reg [IN_W-1:0] max_in = 0;

    always @(posedge ck) begin
        if (en) begin
            // Start the sequence
            src_addr <= 0;
            find_max <= 1;
            max_in <= 0;
        end

        if (level_en) begin
            level_en <= 0;
        end

        if (find_max && !level_en) begin

            // find the largest abs(input)
            if (normal > max_in) begin
                max_in <= normal;
            end

            if (src_addr != CHANS-1) begin
                // request the next input
                src_addr <= src_addr + 1;
            end else begin
                // Finished level acquisition.
                // Start to calculate the level
                level_en <= 1;
                find_max <= 0;
            end

        end
    end

    wire busy;
    assign busy = find_max | level_en | !level_ready;

    assign done = !busy;

endmodule


