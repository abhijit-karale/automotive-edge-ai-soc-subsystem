# Automotive Edge AI Sensor & Accelerator SoC Subsystem

> **High-Performance 64-bit AXI4/APB Interconnect, INT8 Systolic Array AI Accelerator, 32-bit RV32I Processor, Dual-Clock CDC Async FIFO, SECDED Hamming ECC (ISO 26262 ASIL-B), and Automotive Peripherals (CAN-FD, UART)**

---

## 📌 1. Executive Summary

This repository contains a production-grade **Automotive Edge AI & Sensor Processing System-on-Chip (SoC) Subsystem** designed for ADAS (Advanced Driver Assistance Systems) and Automotive Edge AI perception workloads (radar, camera, lidar feature extraction).

Built upon **Japanese Tier-1 Semiconductor Engineering Standards** (*Renesas, Denso, Socionext, Sony Semiconductor*), this project prioritizes **Quality First (品質第一)** and **Monozukuri (ものづくり)** design principles, combining custom hardware acceleration with safety mechanisms.

---

## 🏛 2. System Architecture

```text
 +-----------------------------------------------------------------------------------+
 |                                   SoC SUBSYSTEM                                  |
 |                                                                                   |
 |  +-------------------+              +--------------------+                        |
 |  |  RV32I Core       |              |  Scatter-Gather    |                        |
 |  |  (5-Stage RISC-V) |              |  DMA Engine        |                        |
 |  +--------+----------+              +---------+----------+                        |
 |           | AXI4-Lite M                       | AXI4 Master (R/W 64-bit)          |
 |           v                                   v                                   |
 |  +-------------------------------------------------------+                        |
 |  |                 AXI4 Crossbar Interconnect            |                        |
 |  |                 (64-bit Data, Round-Robin Arb)        |                        |
 |  +----+----------------------+--------------------+------+                        |
 |       |                      |                    |                               |
 |       v                      v                    v                               |
 |  +----+-----------+    +-----+----------+   +-----+------------+                  |
 |  |  SRAM Memory   |    | Custom AI      |   | AXI4-to-APB      |                  |
 |  |  Subsystem     |    | Accelerator    |   | Bridge           |                  |
 |  |  (256KB w/ ECC)|    | (INT8 MAC 4x4) |   +--------+---------+                  |
 |  +----------------+    +----------------+            | APB Bus (32-bit)           |
 |                                                      v                            |
 |                                             +--------+---------+                  |
 |                                             | CDC Async FIFO   |                  |
 |                                             | (Dual Clock)     |                  |
 |                                             +--------+---------+                  |
 |                                                      | clk_pclk (50MHz)           |
 |                                                      v                            |
 |                                             +--------+---------+                  |
 |                                             | Automotive       |                  |
 |                                             | CAN-FD & UART    |                  |
 |                                             | Sensor IF        |                  |
 |                                             +------------------+                  |
 +-----------------------------------------------------------------------------------+
```

### Key Subsystem Components
1. **32-bit RV32I RISC-V CPU Core**: 5-stage classic pipeline (Fetch, Decode, Execute, Memory, Writeback) with hazard detection and ALU execution.
2. **4x4 INT8 Systolic Array AI Accelerator**: High-throughput Multiply-Accumulate (MAC) engine paired with scale/shift quantization and non-linear ReLU activation.
3. **64-bit AXI4 Crossbar Interconnect**: Multi-master (CPU, DMA) to multi-slave (SRAM, Accelerator CSRs, APB Bridge) bus interconnect with fair round-robin arbitration.
4. **Dual-Clock Domain Crossing (CDC) Async FIFO**: 2FF Gray-code pointer synchronizers enabling seamless cross-domain transfers between `clk_soc` (200MHz) and `clk_pclk` (50MHz).
5. **On-Chip SRAM with SECDED ECC**: 256KB memory subsystem protected by Single Error Correction, Double Error Detection (SECDED) Hamming code logic for **ISO 26262 ASIL-B** functional safety compliance.
6. **Automotive Peripherals**: APB-mapped CAN-FD controller stub and UART sensor interface for automotive sensor data ingress/egress.

---

## 🗺 3. Subsystem Memory Map & Register Layout

### Memory Map
| Base Address   | End Address     | Size  | Peripheral / Target Module | Access | Clock Domain |
|----------------|-----------------|-------|----------------------------|--------|--------------|
| `0x0000_0000`  | `0x0000_FFFF`   | 64KB  | Boot ROM                   | R/X    | `clk_soc` (200MHz) |
| `0x2000_0000`  | `0x2003_FFFF`   | 256KB | On-Chip SRAM (w/ SECDED ECC)| R/W/X | `clk_soc` (200MHz) |
| `0x4000_0000`  | `0x4000_00FF`   | 256B  | AI Accelerator CSRs        | R/W    | `clk_soc` (200MHz) |
| `0x5000_0000`  | `0x5000_00FF`   | 256B  | AXI-to-APB Bridge CSRs     | R/W    | `clk_soc` (200MHz) |
| `0x5000_1000`  | `0x5000_13FF`   | 1KB   | CAN-FD Controller CSRs     | R/W    | `clk_pclk` (50MHz) |
| `0x5000_2000`  | `0x5000_20FF`   | 256B  | UART Sensor Interface CSRs | R/W    | `clk_pclk` (50MHz) |

### AI Accelerator Control & Status Registers (`ACCEL_BASE = 0x4000_0000`)
| Offset | Register Name   | Access | Description & Bit Fields |
|--------|-----------------|--------|--------------------------|
| `0x00` | `ACCEL_CTRL`    | R/W    | `[0]` START (Self-clearing pulse), `[1]` INT_EN, `[2]` SOFT_RESET, `[5:3]` MODE, `[8]` DMA_EN |
| `0x04` | `ACCEL_STATUS`  | R/W1C  | `[0]` BUSY (R), `[1]` DONE (W1C), `[2]` OVERFLOW_ERR (W1C), `[3]` BUS_ERR (W1C) |
| `0x08` | `ACCEL_SRC_ADDR`| R/W    | 32-bit SRAM Memory Address for Input Matrix/Features |
| `0x0C` | `ACCEL_DST_ADDR`| R/W    | 32-bit SRAM Memory Address for Output Inference Results |
| `0x10` | `ACCEL_DIM`     | R/W    | `[15:0]` Dimension N, `[31:16]` Dimension M |
| `0x14` | `ACCEL_QUANT`   | R/W    | `[7:0]` Scale Factor, `[15:8]` Right-Shift Amount, `[16]` ReLU Enable |

---

## 📂 4. Repository Structure

```text
.
├── rtl/                        # SystemVerilog RTL Source Files
│   ├── accelerator/            # AI Accelerator IP Block
│   │   ├── accel_mac_array.sv  # 4x4 INT8 Systolic Array MAC Engine
│   │   ├── accel_quantizer.sv  # Scale/Shift Quantizer & ReLU Activation
│   │   ├── accel_csr_regs.sv   # Control & Status Register Map (CSRs)
│   │   └── accel_fsm_control.sv# Accelerator Execution FSM
│   ├── core/                   # 32-bit RISC-V Processor Core
│   │   ├── rv32i_core.sv       # 5-Stage CPU Core Top Level
│   │   ├── rv32i_alu.sv        # Arithmetic Logic Unit
│   │   ├── rv32i_ctrl.sv       # Instruction Control & Opcode Decoder
│   │   └── rv32i_regfile.sv    # 32x32-bit Register File (x0-x31)
│   ├── interconnect/           # System Bus & Clock Domain Crossing
│   │   ├── axi4_crossbar.sv    # 64-bit 2-Master / 3-Slave AXI4 Crossbar
│   │   ├── axi_to_apb_bridge.sv# AXI4-Lite to APB3 Bridge with CDC
│   │   └── cdc_async_fifo.sv   # Dual-Clock Asynchronous Gray-Code FIFO
│   ├── memory/                 # Memory Subsystem
│   │   ├── ecc_hamming.sv      # SECDED Hamming Code Logic
│   │   └── sram_256k_ecc.sv    # 256KB SRAM with SECDED ECC Protection
│   ├── peripherals/            # Low-Speed Automotive Peripherals
│   │   ├── can_fd_controller.sv# CAN-FD Controller Interface
│   │   └── uart_sensor_if.sv   # UART Sensor Interface
│   └── top/
│       └── soc_top.sv          # System Subsystem Top Wrapper
├── verification/               # Verification & Test Suites
│   ├── testbenches/            # SystemVerilog Testbenches
│   │   ├── tb_soc_top.sv       # Top-Level SoC Subsystem Testbench
│   │   ├── tb_accel_mac_array.sv# INT8 Systolic Array MAC Unit Test
│   │   ├── tb_ecc_hamming.sv   # SECDED ECC Safety Unit Test
│   │   └── tb_cdc_async_fifo.sv# CDC Async FIFO Unit Test
│   ├── dpi_c/                  # SystemVerilog DPI-C Golden Models
│   │   ├── accel_ref_model.c   # C++ Golden Reference Matrix MAC Model
│   │   └── accel_ref_model.h   # C++ Golden Model Header
│   └── formal/                 # Formal Verification Proofs (JasperGold)
│       ├── accel_formal_props.sv# SystemVerilog Assertions (SVA)
│       └── formal_spec.tcl     # JasperGold TCL Setup Script
├── firmware/                   # Embedded RISC-V Bare-Metal Drivers
│   ├── driver/                 # Hardware Driver APIs
│   │   ├── accel_driver.c      # AI Accelerator Driver & Interrupt Handler
│   │   └── accel_driver.h      # Driver Headers & Address Definitions
│   └── apps/
│       └── main.c              # Edge AI Inference Bring-up Application
├── docs/                       # Architecture & Technical Specs
│   ├── ARCHITECTURE.md         # Detailed System Architecture Spec
│   ├── REGISTER_MAP.md         # Full Control Register Specification
│   └── VERIFICATION_PLAN.md    # UVM, Formal, & DPI-C Verification Plan
├── run_sim.bat                 # 🚀 One-Click Windows CMD Simulation Script
├── run_sim.ps1                 # 🚀 One-Click PowerShell Simulation Script
├── view_waves.bat              # 🌊 Launch GUI Waveform Viewer (CMD)
├── view_waves.ps1              # 🌊 Launch GUI Waveform Viewer (PowerShell)
└── README.md                   # Project Overview & Quick Start Guide
```

---

## 🚀 5. How to Run & Verify the Project

### Prerequisites
- **EDA Simulator**: QuestaSim / ModelSim (or Icarus Verilog / Verilator).
- **Environment**: Windows (PowerShell / Command Prompt) or Linux.

---

### Option A: One-Click Execution (Recommended)

Simply execute the batch or PowerShell script from the repository root:

#### Windows Command Prompt (CMD):
```cmd
.\run_sim.bat
```

#### Windows PowerShell:
```powershell
.\run_sim.ps1
```

This automated script performs:
1. Compiles all SystemVerilog RTL modules and testbenches.
2. Runs **Top-Level SoC Integration Test** (`tb_soc_top`).
3. Runs **INT8 Systolic Array MAC Engine Unit Test** (`tb_accel_mac_array`).
4. Runs **SECDED ECC Safety Unit Test** (`tb_ecc_hamming`).
5. Runs **Dual-Clock Async CDC FIFO Unit Test** (`tb_cdc_async_fifo`).

---

### Option B: Manual Command Line Simulation (QuestaSim / ModelSim)

If you prefer running commands manually:

```powershell
# 1. Create work library
vlib work

# 2. Compile RTL modules and testbenches
vlog -sv -work work rtl/accelerator/*.sv rtl/core/*.sv rtl/interconnect/*.sv rtl/memory/*.sv rtl/peripherals/*.sv rtl/top/*.sv verification/testbenches/*.sv

# 3. Run Top-Level SoC Subsystem Simulation
vsim -c tb_soc_top -do "log -r /*; run -all; quit"

# 4. Run Individual Unit Testbenches
vsim -c tb_accel_mac_array -do "log -r /*; run -all; quit"
vsim -c tb_ecc_hamming     -do "log -r /*; run -all; quit"
vsim -c tb_cdc_async_fifo  -do "log -r /*; run -all; quit"
```

---

## 🌊 6. Waveform Viewing & Signal Debugging

### Option A: Launch Interactive QuestaSim GUI Waveform Viewer
To view live waveform traces with all signals loaded:

```cmd
.\view_waves.bat
```
*or in PowerShell:*
```powershell
.\view_waves.ps1
```

### Option B: GTKWave or External VCD Trace Viewer
During simulation, standard VCD dumps are automatically generated at `sim/dump.vcd`. You can open this file in GTKWave or any waveform viewer:
```bash
gtkwave sim/dump.vcd
```

---

## 🛡 7. Verification & Functional Safety

### Verification Suite Testbenches
| Testbench Name | Scope & Objective |
|----------------|-------------------|
| [`tb_soc_top.sv`](file:///c:/Users/abhij/OneDrive/Documents/RTL%20Project/New%20folder/verification/testbenches/tb_soc_top.sv) | Full SoC Subsystem Integration Test (Clock/Reset release, RISC-V PC boot vector initialization & pipeline execution). |
| [`tb_accel_mac_array.sv`](file:///c:/Users/abhij/OneDrive/Documents/RTL%20Project/New%20folder/verification/testbenches/tb_accel_mac_array.sv) | $4\times 4$ INT8 Systolic Array MAC engine unit test verifying matrix dot products against expected hardware accumulators. |
| [`tb_ecc_hamming.sv`](file:///c:/Users/abhij/OneDrive/Documents/RTL%20Project/New%20folder/verification/testbenches/tb_ecc_hamming.sv) | SECDED Hamming ECC unit test verifying clean data pass-through, single-bit error detection, and double-bit error detection. |
| [`tb_cdc_async_fifo.sv`](file:///c:/Users/abhij/OneDrive/Documents/RTL%20Project/New%20folder/verification/testbenches/tb_cdc_async_fifo.sv) | Dual-clock asynchronous FIFO domain crossing test verifying write/read pointer synchronization across $200\text{ MHz} \rightarrow 50\text{ MHz}$ clocks. |

### Functional Safety Features (ISO 26262 ASIL-B)
- **SECDED ECC Protection**: Single-bit data corruption is corrected on the fly; double-bit corruption raises `ecc_fault_nmi_o` Non-Maskable Interrupt.
- **AXI Bus Error Response**: Slave errors (`SLVERR`/`DECERR`) are trapped and reported via status register bits and interrupt line.
- **Metastability Hardening**: All clock-domain crossing boundaries utilize 2FF Gray-code pointer synchronization.

---

## 📜 8. License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
