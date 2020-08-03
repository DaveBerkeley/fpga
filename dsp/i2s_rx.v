
module i2s_rx
    #(parameter WIDTH=5)
   (input wire ck,
    input wire sample, // sample the data in here
    input wire [5:0] frame_posn,
    input wire sd,  // I2S data in
    output reg [15:0] left, 
    output reg [15:0] right
);

    // The 24-bit data from the mic, starts at t=2 (I2S spec)
    // Only use the first 16-bits, the trailing bits are noise.

    initial left = 0;
    initial right = 0;

    // shift the microphone data into 16-bit shift register. 
    reg [15:0] shift = 0;

    parameter EOW_LEFT = 17;
    parameter EOW_RIGHT = EOW_LEFT + 32;

    always @(posedge ck) begin

        if (sample) begin

            shift <= { shift[14:0], sd };

            if (frame_posn == EOW_LEFT)
                left <= shift;

            if (frame_posn == (EOW_RIGHT))
                right <= shift;

        end

    end

endmodule

