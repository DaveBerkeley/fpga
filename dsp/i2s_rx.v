
module i2s_rx
    #(parameter BITS=16)
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

    parameter EOW_LEFT = 1 + BITS;
    parameter EOW_RIGHT = EOW_LEFT + 32;

    always @(posedge ck) begin

        if (sample) begin

            shift <= { shift[BITS-2:0], sd };

            if (frame_posn == EOW_LEFT) begin
                left <= shift;
            end

            if (frame_posn == (EOW_RIGHT)) begin
                right <= shift;
            end

        end

    end

endmodule

