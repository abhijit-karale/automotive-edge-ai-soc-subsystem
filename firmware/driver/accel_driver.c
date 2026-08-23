/**
 * @file accel_driver.c
 * @brief Bare-Metal C Driver Implementation for RISC-V RV32I Core
 */

#include "accel_driver.h"

static volatile uint8_t g_accel_done_flag = 0;

void __attribute__((interrupt("machine"))) accel_isr(void) {
    uint32_t status = REG32(ACCEL_BASE_ADDR + ACCEL_STATUS_OFF);
    if (status & STATUS_DONE) {
        REG32(ACCEL_BASE_ADDR + ACCEL_STATUS_OFF) = STATUS_DONE; // Clear W1C
        g_accel_done_flag = 1;
    }
}

void accel_init(void) {
    REG32(ACCEL_BASE_ADDR + ACCEL_CTRL_OFF) = CTRL_INT_EN | CTRL_DMA_EN;
}

int accel_run_inference(uint32_t src_addr, uint32_t dst_addr, uint16_t M, uint16_t N, uint8_t scale, uint8_t shift) {
    g_accel_done_flag = 0;

    REG32(ACCEL_BASE_ADDR + ACCEL_SRC_OFF)   = src_addr;
    REG32(ACCEL_BASE_ADDR + ACCEL_DST_OFF)   = dst_addr;
    REG32(ACCEL_BASE_ADDR + ACCEL_DIM_OFF)   = ((uint32_t)M << 16) | (N & 0xFFFFU);
    REG32(ACCEL_BASE_ADDR + ACCEL_QUANT_OFF) = ((uint32_t)shift << 8) | scale | (1U << 16);

    uint32_t ctrl = REG32(ACCEL_BASE_ADDR + ACCEL_CTRL_OFF);
    REG32(ACCEL_BASE_ADDR + ACCEL_CTRL_OFF) = ctrl | CTRL_START;

    uint32_t timeout = 1000000U;
    while (!g_accel_done_flag && --timeout);

    return (timeout == 0) ? -1 : 0;
}

void can_transmit_result(uint32_t result_val) {
    REG32(CAN_BASE_ADDR + CAN_TX_FIFO_OFF) = result_val;
}
