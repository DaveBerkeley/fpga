
   /*
    *
    */

module shifter
    #(parameter SHIFT_W=5)
    ( input wire ck,
    input wire en,
    input wire [(SHIFT_W-1):0] shift,
    input wire [39:0] in,
    output reg [15:0] out,
    output wire overflow
);

    reg ovf = 0;
    assign overflow = ovf;

    always @(posedge ck) begin

        if (en) begin

            case (shift)
                 0 : begin out <= in[15:0];  ovf <= | in[39:16]; end
                 1 : begin out <= in[16:1];  ovf <= | in[39:17]; end
                 2 : begin out <= in[17:2];  ovf <= | in[39:18]; end
                 3 : begin out <= in[18:3];  ovf <= | in[39:19]; end
                 4 : begin out <= in[19:4];  ovf <= | in[39:20]; end
                 5 : begin out <= in[20:5];  ovf <= | in[39:21]; end
                 6 : begin out <= in[21:6];  ovf <= | in[39:22]; end
                 7 : begin out <= in[22:7];  ovf <= | in[39:23]; end
                 8 : begin out <= in[23:8];  ovf <= | in[39:24]; end
                 9 : begin out <= in[24:9];  ovf <= | in[39:25]; end
                10 : begin out <= in[25:10]; ovf <= | in[39:26]; end
                11 : begin out <= in[26:11]; ovf <= | in[39:27]; end
                12 : begin out <= in[27:12]; ovf <= | in[39:28]; end
                13 : begin out <= in[28:13]; ovf <= | in[39:29]; end
                14 : begin out <= in[29:14]; ovf <= | in[39:30]; end
                15 : begin out <= in[30:15]; ovf <= | in[39:31]; end
                16 : begin out <= in[31:16]; ovf <= | in[39:32]; end
                17 : begin out <= in[32:17]; ovf <= | in[39:33]; end
                18 : begin out <= in[33:18]; ovf <= | in[39:34]; end
                19 : begin out <= in[34:19]; ovf <= | in[39:35]; end
                20 : begin out <= in[35:20]; ovf <= | in[39:36]; end
                21 : begin out <= in[36:21]; ovf <= | in[39:37]; end
                22 : begin out <= in[37:22]; ovf <= | in[39:38]; end
                23 : begin out <= in[38:23]; ovf <= | in[39:39]; end
                24 : begin out <= in[39:24]; ovf <= 0; end
                default : out <= 0;
            endcase
        end else begin
            out <= 0;
        end
    end

endmodule


