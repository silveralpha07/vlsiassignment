module uart_top (
    input wire clk, reset,
    input wire rx,
    output wire tx,
    output wire [7:0] rx_data,
    output wire rx_done,
    output wire rx_error
);
    wire baud_tick;
    wire tx_busy;
    reg tx_start;
    reg [7:0] tx_data;

    baud_gen #(50000000, 9600) baud_gen_inst (
        .clk(clk),
        .reset(reset),
        .tick(baud_tick)
    );

    uart_tx tx_inst (
        .clk(clk),
        .reset(reset),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .baud_tick(baud_tick),
        .tx(tx),
        .tx_busy(tx_busy)
    );

    uart_rx rx_inst (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .baud_tick(baud_tick),
        .rx_data(rx_data),
        .rx_done(rx_done),
        .rx_error(rx_error)
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tx_start <= 0;
        end else if (rx_done && !tx_busy) begin
            tx_data <= rx_data;  // Echo back
            tx_start <= 1;
        end else begin
            tx_start <= 0;
        end
    end
endmodule
