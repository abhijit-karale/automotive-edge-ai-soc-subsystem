/**
 * @file main.c
 * @brief Automotive AI Edge Inference Bringup Application
 */

#include "accel_driver.h"

int main(void) {
    accel_init();

    uint32_t input_sram_buf  = 0x20001000U;
    uint32_t output_sram_buf = 0x20002000U;

    // Run 4x4 INT8 Matrix Inference with scale=0x1A, shift=3
    if (accel_run_inference(input_sram_buf, output_sram_buf, 4, 4, 0x1A, 3) == 0) {
        uint32_t top_classification = REG32(output_sram_buf);
        can_transmit_result(top_classification);
    }

    while (1);
    return 0;
}
