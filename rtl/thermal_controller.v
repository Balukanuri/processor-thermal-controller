`timescale 1ns / 1ps

module thermal_controller #(
    parameter WARN_HI   = 8'd60,
    parameter WARN_LO   = 8'd55,
    parameter CRIT_HI   = 8'd80,
    parameter CRIT_LO   = 8'd75,
    parameter SHUT_HI   = 8'd95,
    parameter WD_CYCLES = 32'd1_000_000,
    parameter PWM_BITS  = 8
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  temp_data,
    input  wire        temp_valid,
    output reg  [2:0]  fan_speed,
    output wire        fan_pwm,
    output reg         throttle,
    output reg         shutdown,
    output reg         fault,
    output reg  [2:0]  state_out,
    output reg  [7:0]  temp_latched
);

    // ================= FSM STATES =================
    localparam [2:0]
        S_IDLE      = 3'd0,
        S_NORMAL    = 3'd1,
        S_WARM      = 3'd2,
        S_HOT       = 3'd3,
        S_EMERGENCY = 3'd4,
        S_FAULT     = 3'd5;

    reg [2:0] state, next_state;

    // ================= WATCHDOG =================
    reg [31:0] wd_cnt;
    reg        wd_expired;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wd_cnt <= 0;
            wd_expired <= 0;
        end else if (temp_valid) begin
            wd_cnt <= 0;
            wd_expired <= 0;
        end else begin
            if (wd_cnt < WD_CYCLES)
                wd_cnt <= wd_cnt + 1;
            else
                wd_expired <= 1;
        end
    end

    // ================= TEMP LATCH =================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            temp_latched <= 0;
        else if (temp_valid)
            temp_latched <= temp_data;
    end

    // ================= STATE REGISTER =================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= S_IDLE;
        else
            state <= next_state;
    end

    // ================= NEXT STATE LOGIC =================
    always @(*) begin
        next_state = state;

        case (state)
            S_IDLE:
                if (temp_valid)
                    next_state = S_NORMAL;

            S_NORMAL:
                if (wd_expired)
                    next_state = S_FAULT;
                else if (temp_latched >= WARN_HI)
                    next_state = S_WARM;

            S_WARM:
                if (wd_expired)
                    next_state = S_FAULT;
                else if (temp_latched >= CRIT_HI)
                    next_state = S_HOT;
                else if (temp_latched < WARN_LO)
                    next_state = S_NORMAL;

            S_HOT:
                if (wd_expired)
                    next_state = S_FAULT;
                else if (temp_latched >= SHUT_HI)
                    next_state = S_EMERGENCY;
                else if (temp_latched < CRIT_LO)
                    next_state = S_WARM;

            S_EMERGENCY:
                next_state = S_EMERGENCY;

            S_FAULT:
                next_state = S_FAULT;

            default:
                next_state = S_IDLE;
        endcase
    end

    // ================= OUTPUT LOGIC (MOORE) =================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fan_speed <= 0;
            throttle  <= 0;
            shutdown  <= 0;
            fault     <= 0;
            state_out <= S_IDLE;
        end else begin
            state_out <= state;

            case (state)
                S_IDLE: begin
                    fan_speed <= 0;
                    throttle  <= 0;
                    shutdown  <= 0;
                    fault     <= 0;
                end

                S_NORMAL: begin
                    fan_speed <= 1;
                    throttle  <= 0;
                    shutdown  <= 0;
                    fault     <= 0;
                end

                S_WARM: begin
                    fan_speed <= 3;
                    throttle  <= 0;
                    shutdown  <= 0;
                    fault     <= 0;
                end

                S_HOT: begin
                    fan_speed <= 5;
                    throttle  <= 1;
                    shutdown  <= 0;
                    fault     <= 0;
                end

                S_EMERGENCY: begin
                    fan_speed <= 7;
                    throttle  <= 1;
                    shutdown  <= 1;
                    fault     <= 0;
                end

                S_FAULT: begin
                    fan_speed <= 7;
                    throttle  <= 1;
                    shutdown  <= 1;
                    fault     <= 1;
                end

                default: begin
                    fan_speed <= 0;
                    throttle  <= 0;
                    shutdown  <= 0;
                    fault     <= 0;
                end
            endcase
        end
    end

    // ================= PWM =================
    pwm_gen #(.BITS(PWM_BITS)) u_pwm (
        .clk(clk),
        .rst_n(rst_n),
        .duty({fan_speed, 5'b00000}),
        .pwm_out(fan_pwm)
    );

endmodule
module pwm_gen #(parameter BITS = 8)(
    input  wire clk,
    input  wire rst_n,
    input  wire [BITS-1:0] duty,
    output reg pwm_out
);

    reg [BITS-1:0] counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            pwm_out <= 0;
        end else begin
            counter <= counter + 1;
            pwm_out <= (counter < duty);
        end
    end

endmodule
