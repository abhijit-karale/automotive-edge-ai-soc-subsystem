# Control & Status Register (CSR) Map
## AI Accelerator CSRs (`ACCEL_BASE = 0x4000_0000`)

---

| Offset | Register Name   | Reset Val  | Access | Description & Bit Layout |
|--------|-----------------|------------|--------|--------------------------|
| `0x00` | `ACCEL_CTRL`    | `0x0000000`| R/W    | `[0]` START (Self-clearing write 1)<br>`[1]` INT_EN (Interrupt Enable)<br>`[2]` SOFT_RESET<br>`[5:3]` MODE (000: MAC, 001: Conv1D, 010: ReLU)<br>`[8]` DMA_EN |
| `0x04` | `ACCEL_STATUS`  | `0x0000000`| R/W1C  | `[0]` BUSY (R)<br>`[1]` DONE (R/W1C)<br>`[2]` OVERFLOW_ERR (R/W1C)<br>`[3]` BUS_ERR (R/W1C) |
| `0x08` | `ACCEL_SRC_ADDR`| `0x0000000`| R/W    | 32-bit SRAM Memory Address for Input Matrix/Feature Map |
| `0x0C` | `ACCEL_DST_ADDR`| `0x0000000`| R/W    | 32-bit SRAM Memory Address for Output Results |
| `0x10` | `ACCEL_DIM`     | `0x0000000`| R/W    | `[15:0]` Matrix Dimension N, `[31:16]` Matrix Dimension M |
| `0x14` | `ACCEL_QUANT`   | `0x0000000`| R/W    | `[7:0]` Scale Factor, `[15:8]` Shift Amount, `[16]` ReLU Enable |
