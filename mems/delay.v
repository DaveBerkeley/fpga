
module DELAY(ws, data_in, in_idx, out_offset, data_out);

input ws;
input [15:0] data_in;
input [6:0] in_idx;
input [6:0] out_offset;
output [15:0] data_out;

reg [15:0] audio;

reg [15:0] ram[0:255];

always @(negedge ws) begin
    ram[in_idx] = data_in;
    audio <= ram[in_idx + out_offset];
end

assign data_out = audio;

endmodule

