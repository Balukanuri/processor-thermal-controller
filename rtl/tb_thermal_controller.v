`timescale 1ns / 1ps

module tb_thermal_controller;

    // DUT signals
    reg clk;
    reg rst_n;
    reg [7:0] temp_data;
    reg temp_valid;

    wire [2:0] fan_speed;
    wire fan_pwm;
    wire throttle, shutdown, fault;
    wire [2:0] state_out;
    wire [7:0] temp_latched;

    // Instantiate DUT
    thermal_controller #(
        .WARN_HI   (8'd60),
        .WARN_LO   (8'd55),
        .CRIT_HI   (8'd80),
        .CRIT_LO   (8'd75),
        .SHUT_HI   (8'd95),
        .WD_CYCLES (32'd50),   // small for simulation
        .PWM_BITS  (8)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .temp_data(temp_data),
        .temp_valid(temp_valid),
        .fan_speed(fan_speed),
        .fan_pwm(fan_pwm),
        .throttle(throttle),
        .shutdown(shutdown),
        .fault(fault),
        .state_out(state_out),
        .temp_latched(temp_latched)
    );

    // Clock generation (100 MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    // Stimulus task
    task send_temp(input [7:0] t);
    begin
        @(posedge clk);
        temp_data  <= t;
        temp_valid <= 1;

        @(posedge clk);
        temp_valid <= 0;

        repeat(5) @(posedge clk);
    end
    endtask

    // Initial block
    initial begin
        // Initialize everything
        clk = 0;
        rst_n = 0;
        temp_data = $random % 120;
        temp_valid = 0;
        
        

        // Dump waves
        $dumpfile("thermal.vcd");
        $dumpvars(0, tb_thermal_controller);

        // Reset sequence
        repeat(5) @(posedge clk);
        rst_n = 1;

        $display("\n==== START TEST ====\n");

        // NORMAL
        send_temp(30);
        $display("NORMAL: state=%0d fan=%0d", state_out, fan_speed);

        // WARM
        send_temp(65);
        $display("WARM: state=%0d fan=%0d", state_out, fan_speed);

        // HOT
        send_temp(85);
        $display("HOT: state=%0d fan=%0d throttle=%b", state_out, fan_speed, throttle);

        // EMERGENCY
        send_temp(100);
        $display("EMERGENCY: state=%0d shutdown=%b", state_out, shutdown);

        // Drop temp (should stay EMERGENCY)
        send_temp(20);
        $display("STILL EMERGENCY: state=%0d", state_out);

        // Reset
        rst_n = 0;
        repeat(5) @(posedge clk);
        rst_n = 1;

        send_temp(40);
        $display("BACK TO NORMAL: state=%0d", state_out);

        // Watchdog test
        $display("Testing watchdog...");
        repeat(100) @(posedge clk);
        $display("FAULT: state=%0d fault=%b", state_out, fault);

        $display("\n==== END TEST ====\n");

        #100;
        $finish;
    end

    initial begin
    clk = 0;
    rst_n = 0;
    temp_data = 0;
    temp_valid = 0;

    // Reset
    repeat(5) @(posedge clk);
    rst_n = 1;

    // 👇 ADD YOUR REALISTIC RANDOM TEST HERE
    repeat (20) begin
        @(posedge clk);
        temp_data  = $random % 120;
        temp_valid = 1;

        @(posedge clk);
        temp_valid = 0;

        repeat(5) @(posedge clk); // let FSM settle
    end

    #100;
    $finish;
end
    // Monitor (continuous debug)
    initial begin
        $monitor("T=%0t | state=%0d temp=%0d fan=%0d thr=%b shut=%b fault=%b",
                 $time, state_out, temp_latched, fan_speed,
                 throttle, shutdown, fault);
    end
    
    
    always @(posedge clk) begin
    // Shutdown must always imply throttle
    if (shutdown && !throttle) begin
        $display("ERROR: Shutdown without throttle at time %0t", $time);
    end

    // Emergency must have max fan
    if (state_out == 3'd4 && fan_speed != 3'd7) begin
        $display("ERROR: Emergency without max fan at time %0t", $time);
    end

    // Fault must assert shutdown
    if (state_out == 3'd5 && !shutdown) begin
        $display("ERROR: Fault without shutdown at time %0t", $time);
    end
    repeat (20) begin
    @(posedge clk);
    temp_data  = $random % 120;
    temp_valid = 1;

    @(posedge clk);
    temp_valid = 0;
end
end


endmodule