# System Architecture Specification
## Automotive Edge Sensor & AI Accelerator SoC Subsystem

---

## 1. High-Level Interconnect Topology
The subsystem integrates a 32-bit RV32I RISC-V core with an INT8 Systolic Array Hardware Accelerator over a 64-bit AXI4 Crossbar Interconnect operating in the high-speed clock domain (`clk_soc` @ 200MHz). Low-speed automotive peripherals (CAN-FD Controller, UART Sensor Interface) operate in a separate clock domain (`clk_pclk` @ 50MHz) connected through a Dual-Clock Asynchronous CDC FIFO and AXI-to-APB Bridge.

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

---

## 2. Functional Safety Architecture (ISO 26262 ASIL-B Alignment)
1. **SECDED ECC Protection**: The 256KB On-Chip SRAM incorporates Hamming Single Error Correction, Double Error Detection (SECDED) logic. Uncorrectable 2-bit ECC errors trigger a Non-Maskable Interrupt (`NMI_ECC_FAULT`) to the CPU.
2. **AXI Bus Error Traps**: Invalid memory address access or slave bus errors (`SLVERR`/`DECERR`) set status bit 3 in `ACCEL_STATUS` and raise a high-priority safety interrupt.
3. **Metastability-Hardened CDC**: Dual-clock Gray pointer synchronizers (2FF) prevent metastability and guarantee single-bit toggle transitions across clock boundaries.
