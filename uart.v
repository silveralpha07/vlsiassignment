/* baud rate generator */

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



/* UART Transmitter module */

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


/* UART Receiver module */

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



/* UART top(tb) module */

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
