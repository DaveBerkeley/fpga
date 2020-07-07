
module top (
    input wire CLK, 
    output wire LED0,
    output wire LED1,
    output wire LED2,
    output wire LED3,
    output wire LED4,
    output wire LED5,
    output wire LED6,
    output wire LED7
);

    wire ck;
    assign ck = CLK;

    reg [20:0] prescale = 0;

    always @(negedge ck) begin
        prescale <= prescale + 1;
    end
 
    reg [7:0] counter = 0;

    wire next;
    assign next = (counter == 0) ? 1 : 0;

    always @(negedge ck) begin
        if (prescale == 0)
            counter <= { counter[6:0], next };
    end

    assign LED0 = counter[0];
    assign LED1 = counter[1];
    assign LED2 = counter[2];
    assign LED3 = counter[3];
    assign LED4 = counter[4];
    assign LED5 = counter[5];
    assign LED6 = counter[6];
    assign LED7 = counter[7];

endmodule
