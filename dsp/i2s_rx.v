
module i2s_rx
    #(parameter BITS=16, CLOCKS=64)
   (input wire ck,
    input wire sample, // sample the data in here
    input wire [5:0] frame_posn,
    input wire sd,  // I2S data in
    output reg [BITS-1:0] left, 
    output reg [BITS-1:0] right
);

    // The 24-bit data from the mic, starts at t=2 (I2S spec)

    initial left = 0;
    initial right = 0;

    // shift the microphone data into N-bit shift register. 
    reg [BITS-1:0] shift = 0;

    wire [5:0] EOW_LEFT;
    wire [5:0] EOW_RIGHT;
    wire [5:0] MASK;
    wire [5:0] frame;
    wire [5:0] midpoint;

    generate
        if (CLOCKS==64) begin
            assign MASK = 6'b111111;
            assign midpoint = 32;
        end
        if (CLOCKS==32) begin
            assign MASK = 6'b011111;
            assign midpoint = 16;
        end
    endgenerate

    assign EOW_LEFT = MASK & (1 + BITS);
    assign EOW_RIGHT = MASK & (1 + BITS + midpoint);
    assign frame = frame_posn & MASK;

    always @(posedge ck) begin

        if (sample) begin

            shift <= { shift[BITS-2:0], sd };

            if (frame == EOW_LEFT) begin
                left <= shift;
            end

            if (frame == EOW_RIGHT) begin
                right <= shift;
            end

        end

    end

endmodule

