module traffic_light_controller (
    input clk,
    input reset,
    input emergency_ns,
    input emergency_ew,
    output reg [1:0] ns_light,  // 00 = Red, 01 = Yellow, 10 = Green
    output reg [1:0] ew_light
);

    reg [3:0] timer;
    reg [2:0] state;

    // State encoding
    localparam NS_GREEN   = 3'b000,
               NS_YELLOW  = 3'b001,
               EW_GREEN   = 3'b010,
               EW_YELLOW  = 3'b011,
               EMERGENCY_NS = 3'b100,
               EMERGENCY_EW = 3'b101;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= NS_GREEN;
            timer <= 0;
        end else begin
            case (state)
                NS_GREEN: begin
                    ns_light <= 2'b10;
                    ew_light <= 2'b00;
                    if (emergency_ew) state <= EMERGENCY_EW;
                    else if (timer == 5) begin
                        timer <= 0;
                        state <= NS_YELLOW;
                    end else timer <= timer + 1;
                end

                NS_YELLOW: begin
                    ns_light <= 2'b01;
                    ew_light <= 2'b00;
                    if (emergency_ew) state <= EMERGENCY_EW;
                    else if (timer == 2) begin
                        timer <= 0;
                        state <= EW_GREEN;
                    end else timer <= timer + 1;
                end

                EW_GREEN: begin
                    ns_light <= 2'b00;
                    ew_light <= 2'b10;
                    if (emergency_ns) state <= EMERGENCY_NS;
                    else if (timer == 5) begin
                        timer <= 0;
                        state <= EW_YELLOW;
                    end else timer <= timer + 1;
                end

                EW_YELLOW: begin
                    ns_light <= 2'b00;
                    ew_light <= 2'b01;
                    if (emergency_ns) state <= EMERGENCY_NS;
                    else if (timer == 2) begin
                        timer <= 0;
                        state <= NS_GREEN;
                    end else timer <= timer + 1;
                end

                EMERGENCY_NS: begin
                    ns_light <= 2'b10; // Green
                    ew_light <= 2'b00; // Red
                    if (!emergency_ns) begin
                        timer <= 0;
                        state <= NS_GREEN;
                    end
                end

                EMERGENCY_EW: begin
                    ns_light <= 2'b00;
                    ew_light <= 2'b10;
                    if (!emergency_ew) begin
                        timer <= 0;
                        state <= EW_GREEN;
                    end
                end

                default: begin
                    state <= NS_GREEN;
                end
            endcase
        end
    end
endmodule
