# learn_simple_soc

## 1. Overview

This repository contains a simple SoC design based on the [PicoRV32](https://github.com/cliffordwolf/picorv32) core.  
The SoC includes AXI memory and an LED controller connected via an AXI-Lite interconnect.  
It was created as a self-learning project to understand the basic SoC architecture and the AXI bus interface.


## 2. File Structure

- `picorv32.v`  
  PicoRV32 RISC-V CPU core implementation.

- `axi_memory.sv`  
  AXI memory model supporting read/write operations over AXI bus.

- `axi4lite_interconnect.sv`  
  [AXI-Lite](https://developer.arm.com/documentation/ihi0022/latest) interconnect module connecting master and multiple slaves (memory, peripherals).

- `led_controller.sv`  
  Simple LED control peripheral connected via AXI-Lite.

- `testbench.v`  
  Top-level simulation testbench integrating the SoC components.

- `firmware/`  
  Directory containing firmware source files and scripts for building the HEX program to be loaded into memory.

- Simulation scripts:  
  - `Run_SIM.bat` — Runs ModelSim simulation.  
  - `RUN_VIEW.bat` — Opens waveform viewer with prepared waveforms.  
  - `Wave.do` — ModelSim waveform configuration file for signal observation.

## 3. Operation Environment

This project targets Windows environment using ModelSim for simulation. Use the provided batch scripts for convenience:

- To start simulation:  
  Run `Run_SIM.bat` from the Windows CMD prompt.

- To view waveforms after simulation:  
  Run `RUN_VIEW.bat` to open ModelSim waveform viewer with predefined signals (configured in `Wave.do`).

Add or customize signals to `Wave.do` as needed for detailed debugging.

## 4. Firmware HEX File Generation

**Under Construction** — This section will describe how to build the firmware HEX file from source code using the RISC-V GNU toolchain and conversion scripts.  
Details and instructions will be added soon.

---
