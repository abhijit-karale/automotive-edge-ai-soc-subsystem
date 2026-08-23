/**
 * @file accel_driver.h
 * @brief Header for Automotive Edge AI Accelerator RISC-V Bare-Metal Driver
 */

#ifndef ACCEL_DRIVER_H
#define ACCEL_DRIVER_H

#include <stdint.h>

#define ACCEL_BASE_ADDR     0x40000000U
#define CAN_BASE_ADDR       0x50001000U

#define ACCEL_CTRL_OFF      0x00U
#define ACCEL_STATUS_OFF    0x04U
#define ACCEL_SRC_OFF       0x08U
#define ACCEL_DST_OFF       0x0CU
#define ACCEL_DIM_OFF       0x10U
#define ACCEL_QUANT_OFF     0x14U

#define CAN_TX_FIFO_OFF     0x10U

#define REG32(addr)         (*(volatile uint32_t *)(addr))

#define CTRL_START          (1U << 0)
#define CTRL_INT_EN         (1U << 1)
#define CTRL_DMA_EN         (1U << 8)
#define STATUS_DONE         (1U << 1)

void accel_init(void);
int accel_run_inference(uint32_t src_addr, uint32_t dst_addr, uint16_t M, uint16_t N, uint8_t scale, uint8_t shift);
void can_transmit_result(uint32_t result_val);

#endif // ACCEL_DRIVER_H
