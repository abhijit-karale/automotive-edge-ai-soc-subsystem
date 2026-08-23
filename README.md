# Automotive Edge Sensor & AI Accelerator SoC Subsystem
### High-Performance AXI4/APB Interconnect, INT8 Systolic Array Accelerator, UVM Verification, JasperGold Formal Proofs, and ISO 26262 ASIL-B Safety Mechanisms

---

## 📌 Executive Summary / 概要

This repository contains a production-grade **Automotive Edge AI & Sensor Processing SoC Subsystem** designed for next-generation ADAS/Automotive Edge AI perception workloads. The design features a **32-bit RV32I RISC-V CPU core**, a **4x4 INT8 Systolic Array Hardware Accelerator**, a **64-bit AXI4 Crossbar**, dual-clock domain crossing (CDC) via Gray-code Async FIFOs, and automotive low-speed peripherals (CAN-FD, Sensor IF).

The project is built with **"Quality First" (品質第一)** and **Monozukuri (ものづくり)** engineering principles, tailored directly for Japanese Tier-1 semiconductor standards (**Renesas Electronics, Socionext, Denso, Sony Semiconductor Solution**).

---

## 🏛 System Architecture

```
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

### Key Technical Specs
- **Processor Core**: 32-bit RISC-V RV32I 5-stage pipelined CPU with hazard unit & forwarding.
- **Hardware Accelerator**: 4x4 INT8 Systolic Array MAC engine with fixed-point scaling, right-shift quantizer, and ReLU activation.
- **Interconnect**: 64-bit AXI4 Crossbar Interconnect with round-robin arbitration & AXI-to-APB bridge.
- **Clock Domain Crossing**: Dual-clock Asynchronous FIFO with 2FF Gray-code pointer synchronization (`clk_soc` @ 200MHz, `clk_pclk` @ 50MHz).
- **Functional Safety (ISO 26262 ASIL-B)**: 256KB On-Chip SRAM with SECDED Hamming ECC & AXI bus error traps (`SLVERR`/`DECERR`).
- **Verification Suite**: UVM 1.2 testbench with VIPs, DPI-C C++ Golden Reference Model, and Cadence JasperGold Formal Verification (SVA).

---

## 🗺 Subsystem Memory Map

| Base Address   | End Address     | Size  | Target / Peripheral Module | Access | Clock Domain |
|----------------|-----------------|-------|----------------------------|--------|--------------|
| `0x0000_0000`  | `0x0000_FFFF`   | 64KB  | Boot ROM                   | R/X    | `clk_soc` (200MHz) |
| `0x2000_0000`  | `0x2003_FFFF`   | 256KB | On-Chip SRAM (w/ SECDED ECC)| R/W/X | `clk_soc` (200MHz) |
| `0x4000_0000`  | `0x4000_00FF`   | 256B  | Edge AI Accelerator CSRs   | R/W    | `clk_soc` (200MHz) |
| `0x4000_1000`  | `0x4000_10FF`   | 256B  | Scatter-Gather DMA CSRs    | R/W    | `clk_soc` (200MHz) |
| `0x5000_0000`  | `0x5000_00FF`   | 256B  | AXI-to-APB Bridge CSRs     | R/W    | `clk_soc` (200MHz) |
| `0x5000_1000`  | `0x5000_13FF`   | 1KB   | CAN-FD Controller CSRs     | R/W    | `clk_pclk` (50MHz) |
| `0x5000_2000`  | `0x5000_20FF`   | 256B  | UART Sensor IF CSRs        | R/W    | `clk_pclk` (50MHz) |
| `0xE000_0000`  | `0xE000_0FFF`   | 4KB   | PLIC (Interrupt Controller)| R/W    | `clk_soc` (200MHz) |

---

## 📊 Project Status & Progress Tracker

```markdown
### Week 1/5: RTL Core & Subsystem Interconnect
- [x] Directory Scaffold & Workspace Initialization
- [x] RV32I 5-stage RISC-V CPU Core (Fetch, Decode, Execute, Memory, Writeback)
- [x] Edge AI Accelerator FSM & Control Registers
- [x] INT8 Systolic Array MAC Engine & Quantizer Unit
- [x] 64-bit AXI4 Crossbar Interconnect with Round-Robin Arbitration
- [x] Dual-Clock Async CDC FIFO (Gray-code 2FF)
- [x] 256KB On-Chip SRAM with SECDED Hamming ECC Logic
- [x] AXI-to-APB Bridge & Automotive Peripherals (CAN-FD, UART)
- [x] Subsystem Top Wrapper (`soc_top.sv`)

### Week 2/5: Layered UVM & DPI-C Verification Setup
- [ ] UVM Testbench Environment (`accel_env`, `accel_agent`, `accel_scoreboard`)
- [ ] Golden C Reference Model integrated via SystemVerilog DPI-C
- [ ] Constrained Random Sequence Generation & VIP Integration

### Week 3/5: Formal Verification (JasperGold)
- [ ] SystemVerilog Assertions (SVA) for AXI4 Interconnect Fairness
- [ ] SVA for AXI Deadlock Freedom & Handshake Stability
- [ ] SVA for CDC Async FIFO Pointer Integrity & Single-Bit Toggle
- [ ] JasperGold Proof Convergence Log Execution

### Week 4/5: Embedded C Driver & Bring-Up Firmware
- [ ] RV32I Bare-Metal Driver for AI Accelerator & DMA
- [ ] Machine-Mode Interrupt Service Routines (W1C Clear)
- [ ] End-to-End Inference Application & CAN-FD Payload Dispatch

### Week 5/5: Coverage Closure & Documentation
- [ ] Code Coverage Closure (Target: >98%)
- [ ] Functional Coverage Closure (Target: 100%)
- [ ] Architecture diagrams, waveform snapshots, resume bullet integration
```

---

## 🛠 Quick Start & Verification Build

```bash
# Clone the repository
git clone https://github.com/your-username/automotive_edge_ai_soc.git
cd automotive_edge_ai_soc

# Run basic top-level testbench using Icarus Verilog / ModelSim
vlog rtl/**/*.sv verification/testbenches/tb_soc_top.sv
vsim -novopt tb_soc_top -do "run -all; quit"
```

---

## 📜 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
