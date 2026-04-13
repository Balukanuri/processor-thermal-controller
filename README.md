# Processor Thermal Controller (RTL Design)

## Overview
A hardware-based thermal management system implemented in Verilog.  
Controls fan speed, throttling, and shutdown based on temperature levels.

## Features
- FSM-based control logic
- Hysteresis (prevents oscillation)
- PWM fan control
- Watchdog timer for sensor failure
- Emergency shutdown mechanism

## Architecture
- States: IDLE → NORMAL → WARM → HOT → EMERGENCY → FAULT
- Temperature thresholds define transitions
- PWM controls fan speed dynamically

## Simulation
Testbench verifies:
- Temperature transitions
- Emergency condition
- Recovery behavior
- Random stress testing

## Tools Used
- Verilog HDL
- Xilinx Vivado

## Project Structure
- rtl/ → design
- tb/ → testbench

## Status
✔ RTL Design  
✔ Simulation  
✔ Synthesis  
✔ Implementation  # processor-thermal-controller
