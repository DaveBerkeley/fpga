
   /*
    *
    */

module shifter(
    input wire ck,
    input wire en,
    input wire [4:0] shift,
    input wire [39:0] in,
    output reg [15:0] out
);

    always @(negedge ck) begin
        if (en) begin
            case (shift)
                 0 : out <= in[15:0];
                 1 : out <= in[16:1];
                 2 : out <= in[17:2];
                 3 : out <= in[18:3];
                 4 : out <= in[19:4];
                 5 : out <= in[20:5];
                 6 : out <= in[21:6];
                 7 : out <= in[22:7];
                 8 : out <= in[23:8];
                 9 : out <= in[24:9];
                10 : out <= in[25:10];
                11 : out <= in[26:11];
                12 : out <= in[27:12];
                13 : out <= in[28:13];
                14 : out <= in[29:14];
                15 : out <= in[30:15];
                16 : out <= in[31:16];
                17 : out <= in[32:17];
                18 : out <= in[33:18];
                19 : out <= in[34:19];
                20 : out <= in[35:20];
                21 : out <= in[36:21];
                22 : out <= in[37:22];
                23 : out <= in[38:23];
                24 : out <= in[39:24];
                default : out <= 0;
            endcase
        end else begin
            out <= 0;
        end
    end

endmodule


