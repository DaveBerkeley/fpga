
module I2S_TX(
    input wire sck, // I2S sck
    input wire ws,  // I2S ws
    input wire [15:0] left,
    input wire [15:0] right,
    output reg sd   // data out
);

// Delay the ws signal by half an sck cycle
// So we can load the shift reg without a conflict
// between ws and sck transitions, which occur
// at the same time.

reg ws_delayed;

always @(posedge sck) begin
    ws_delayed <= ws;
end

// half sck pulse following a ws transition
wire ws_pulse;

assign ws_pulse = ws ^ ws_delayed;

//  Shift the data out on every negedge of sck
reg [15:0] shift;

always @(negedge sck) begin
    sd <= shift[15];
    shift <= shift << 1;
end

// Load the shift reg a half sck after the ws transition

always @(negedge ws_pulse) begin
    if (ws)
        shift <= { 1'b0, right };
    else
        shift <= { 1'b0, left };
end

endmodule

