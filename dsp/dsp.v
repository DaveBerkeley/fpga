
   /*
    *
    */

module top (
    input wire CLK, 
    output wire P1A1, 
    output wire P1A2, 
    output wire P1A3, 
    output wire P1A4,
    output wire P1B1,
    output wire P1B2,
    output wire P1B3,
    output wire P1B4,
    output wire LED1,
    output wire LED2,
    output wire LED3,
    output wire LED4,
    output wire LED5
);

    reg [3:0] prescale = 0;

    always @(negedge CLK) begin
        prescale <= prescale + 1;
    end

    wire ck;
    assign ck = prescale[0];

    reg [15:0] a = 0;
    reg [15:0] b = 16'h1;
    wire [31:0] out;

    multiplier mul(.ck(ck), .a(a), .b(b), .out(out));

    always @(negedge ck) begin
        a <= a + 1;
    end

    assign P1A1 = ck;
    assign P1A2 = a[0];
    assign P1A3 = a[1];
    assign P1A4 = a[2];
    assign P1B1 = out[0];
    assign P1B2 = out[1];
    assign P1B3 = out[2];
    assign P1B4 = out[3];

    reg [31:0] shifter = 0;
    reg [5:0] addr = 0;

    always @(negedge ck) begin
        addr <= addr + 1;
        if (addr == 0)
            shifter <= out;
        else
            shifter <= shifter << 1;
    end

    assign LED1 = shifter[31];
    assign LED2 = 0;
    assign LED3 = 0;
    assign LED4 = 0;
    assign LED5 = 0;

endmodule

