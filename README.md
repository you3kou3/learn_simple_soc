# learn_simple_soc

## 1. Overview

This repository contains a simple SoC design built around the PicoRV32 core. The SoC includes AXI memory and an LED controller connected through an AXI-Lite interconnect, aimed as a self-learning project for understanding basic SoC construction and AXI bus interfaces. It is intended to provide a practical platform to study RISC-V CPU core integration, peripheral interfacing, and bus communication in a compact and manageable environment.

## 2. File Structure

- `picorv32.v`  
  PicoRV32 RISC-V CPU core implementation.

- `axi_memory.sv`  
  AXI memory model supporting read/write operations over AXI bus.

- `axi4lite_interconnect.sv`  
  AXI-Lite interconnect module connecting master and multiple slaves (memory, peripherals).

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
