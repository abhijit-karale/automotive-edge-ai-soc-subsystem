# Design Verification Plan (UVM + Formal + DPI-C)
## Automotive Edge AI SoC Subsystem

---

## 1. UVM Verification Architecture
- **Agents**: AXI4 Master VIP, APB3 Master VIP, Accelerator Monitor VIP.
- **Predictor**: Intercepts transactions and invokes C++ Golden Reference Model via SystemVerilog DPI-C (`accel_matrix_mac_c`).
- **Scoreboard**: In-order bit-exact output matrix comparison against expected tensor values from Golden Model.

---

## 2. JasperGold Formal Proof Strategy (SVAs)
- **Arbiter Fairness**: Prove no master is starved indefinitely under round-robin arbitration.
- **Handshake Stability**: Prove `AWVALID`/`WVALID`/`ARVALID` remain asserted until `READY` response.
- **CDC Safety**: Prove Gray-code write pointer undergoes single-bit changes (`$countones(wptr_gray ^ $past(wptr_gray)) <= 1`).
- **Interrupt Persistence**: Prove interrupt line stays high until explicitly cleared via Write-1-to-Clear (`W1C`).
