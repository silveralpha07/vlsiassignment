module uart_rx (
    input wire clk, reset,
    input wire rx,
    input wire baud_tick,
    output reg [7:0] rx_data,
    output reg rx_done,
    output reg rx_error
);
    reg [3:0] bit_index;
    reg [7:0] rx_shift_reg;

    typedef enum reg [2:0] {IDLE, START, DATA, STOP, DONE} state_t;
    state_t state;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            rx_data <= 0;
            rx_done <= 0;
            rx_error <= 0;
        end else if (baud_tick) begin
            case (state)
                IDLE: begin
                    rx_done <= 0;
                    if (!rx) begin // start bit detected
                        state <= START;
                        bit_index <= 0;
                    end
                end

                START: begin
                    state <= DATA;
                end

                DATA: begin
                    rx_shift_reg[bit_index] <= rx;
                    bit_index <= bit_index + 1;
                    if (bit_index == 7) state <= STOP;
                end

                STOP: begin
                    if (rx == 1) begin
                        rx_data <= rx_shift_reg;
                        rx_done <= 1;
                        rx_error <= 0;
                    end else begin
                        rx_error <= 1;
                    end
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
