module uart_tx (
    input wire clk, reset,
    input wire tx_start,
    input wire [7:0] tx_data,
    input wire baud_tick,
    output reg tx,
    output reg tx_busy
);
    reg [3:0] bit_index;
    reg [9:0] tx_shift_reg;

    typedef enum reg [2:0] {IDLE, START, DATA, STOP} state_t;
    state_t state;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tx <= 1;
            tx_busy <= 0;
            bit_index <= 0;
            state <= IDLE;
        end else begin
            if (baud_tick) begin
                case (state)
                    IDLE: begin
                        tx <= 1;
                        tx_busy <= 0;
                        if (tx_start) begin
                            tx_shift_reg <= {1'b1, tx_data, 1'b0}; // stop, data, start
                            bit_index <= 0;
                            state <= START;
                            tx_busy <= 1;
                        end
                    end

                    START: begin
                        tx <= tx_shift_reg[0];
                        tx_shift_reg <= tx_shift_reg >> 1;
                        bit_index <= bit_index + 1;
                        if (bit_index == 9) state <= IDLE;
                    end
                endcase
            end
        end
    end
endmodule
