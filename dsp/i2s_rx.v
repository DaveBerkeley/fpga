
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
    wire [5:0] POSN_MASK;
    wire [5:0] frame;

    assign POSN_MASK = 6'((1 << $clog2(CLOCKS)) - 1);
    assign EOW_LEFT = POSN_MASK & (1 + BITS);
    assign EOW_RIGHT = POSN_MASK & 6'(1 + BITS + (CLOCKS / 2));
    assign frame = frame_posn & POSN_MASK;

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

