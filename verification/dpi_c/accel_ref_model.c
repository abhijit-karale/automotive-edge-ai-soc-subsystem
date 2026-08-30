     /**
 * @file accel_ref_model.c
 * @brief Golden C Reference Model for Matrix MAC & Quantization
 */

#include "accel_ref_model.h"
#include <stdio.h>

void accel_matrix_mac_c(
    int M, int N, int K,
    const int8_t* weight,
    const int8_t* input_feat,
    int32_t* output_mat,
    uint8_t scale,
    uint8_t shift,
    uint8_t relu_en
) {
    for (int i = 0; i < M; i++) {
        for (int j = 0; j < N; j++) {
            int32_t accum = 0;
            for (int k = 0; k < K; k++) {
                accum += (int32_t)weight[i * K + k] * (int32_t)input_feat[k * N + j];
            }
            int32_t scaled = (accum * scale) >> shift;
            if (relu_en && scaled < 0) {
                scaled = 0;
            }
            output_mat[i * N + j] = scaled;
        }
    }
}
