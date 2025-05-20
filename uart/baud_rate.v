module baud_gen #(parameter CLK_FREQ = 50000000, parameter BAUD_RATE = 9600)(
    input wire clk,
    input wire reset,
    output reg tick
);
    localparam COUNT_MAX = CLK_FREQ / BAUD_RATE;
    reg [$clog2(COUNT_MAX)-1:0] count;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            count <= 0;
            tick <= 0;
        end else begin
            if (count == COUNT_MAX - 1) begin
                count <= 0;
                tick <= 1;
            end else begin
                count <= count + 1;
                tick <= 0;
            end
        end
    end
endmodule
