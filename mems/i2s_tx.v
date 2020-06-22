
module I2S_TX(sck, ws, data_l, data_r, data_out);

input sck;
input ws;
input wire [15:0] data_l;
input wire [15:0] data_r;
output data_out;

// Delay the ws signal by half an sck cycle
// So we can load the shift reg without a conflict
// between ws and sck transitions, which occur
// at the same time.

reg ws_delayed;

always @(posedge sck) begin
    ws_delayed <= ws;
end

//  Shift the data out on every negedge of sck
//  An extra MSB is added to give a zero output when the data is loaded
//  on the posedge.
reg [16:0] shift;

always @(negedge sck) begin
    shift <= shift << 1;
end

//  Data out is always the MSB of the shift reg

assign data_out = shift[16];

// Load the shift reg a half sck after the ws transition

always @(posedge ws_delayed) begin
    shift <= { 1'b0, data_r };
end

always @(negedge ws_delayed) begin
    shift <= { 1'b0, data_l };
end

endmodule

