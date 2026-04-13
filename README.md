 Processor Thermal Controller (RTL Design) using Verilog HDL

 Project Overview
This project implements a hardware-based thermal management system. 
Controls fan speed, throttling, and shutdown based on temperature levels.

 Features
- FSM-based control logic
- PWM fan control
- Watchdog timer for sensor failure
- Emergency shutdown mechanism

 Architecture
- States: IDLE → NORMAL → WARM → HOT → EMERGENCY → FAULT
- Temperature thresholds define transitions

 Simulation
Testbench verifies:
- Temperature transitions
- Emergency condition
- Recovery behavior
- Random stress testing

 Tools Used
- Verilog HDL
- Xilinx Vivado

 Project Structure
- rtl/ → design
- tb/ → testbench

