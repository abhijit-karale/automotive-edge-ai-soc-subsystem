/**
 * @file accel_ref_model.h
 * @brief Golden C Reference Model for Matrix MAC & Quantization (DPI-C Header)
 */

#ifndef ACCEL_REF_MODEL_H
#define ACCEL_REF_MODEL_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

void accel_matrix_mac_c(
    int M, int N, int K,
    const int8_t* weight,
    const int8_t* input_feat,
    int32_t* output_mat,
    uint8_t scale,
    uint8_t shift,
    uint8_t relu_en
);

#ifdef __cplusplus
}
#endif

#endif // ACCEL_REF_MODEL_H
