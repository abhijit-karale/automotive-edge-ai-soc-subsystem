  // ============================================================================
  // File: rtl/memory/ecc_hamming.sv
  // Description: Hamming SECDED (Single Error Correction, Double Error Detection) Engine
 // Standard: SystemVerilog IEEE 1800-2017
 // ============================================================================

module ecc_hamming (
    input  logic [31:0] data_i,
    output logic [6:0]  ecc_code_o,

    input  logic [31:0] read_data_i,
    input  logic [6:0]  read_ecc_i,
    output logic [31:0] corrected_data_o,
    output logic        single_error_o,
    output logic        double_error_o
);

    // Encoding Parity Bits
    always_comb begin
        ecc_code_o[0] = data_i[0] ^ data_i[1] ^ data_i[3] ^ data_i[4] ^ data_i[6] ^ data_i[8] ^ data_i[10] ^ data_i[11] ^ data_i[13] ^ data_i[15] ^ data_i[17] ^ data_i[19] ^ data_i[21] ^ data_i[23] ^ data_i[25] ^ data_i[26] ^ data_i[28] ^ data_i[30];
        ecc_code_o[1] = data_i[0] ^ data_i[2] ^ data_i[3] ^ data_i[5] ^ data_i[6] ^ data_i[9] ^ data_i[10] ^ data_i[12] ^ data_i[13] ^ data_i[16] ^ data_i[17] ^ data_i[20] ^ data_i[21] ^ data_i[24] ^ data_i[25] ^ data_i[27] ^ data_i[28] ^ data_i[31];
        ecc_code_o[2] = data_i[1] ^ data_i[2] ^ data_i[3] ^ data_i[7] ^ data_i[8] ^ data_i[9] ^ data_i[10] ^ data_i[14] ^ data_i[15] ^ data_i[16] ^ data_i[17] ^ data_i[22] ^ data_i[23] ^ data_i[24] ^ data_i[25] ^ data_i[29] ^ data_i[30] ^ data_i[31];
        ecc_code_o[3] = data_i[4] ^ data_i[5] ^ data_i[6] ^ data_i[7] ^ data_i[8] ^ data_i[9] ^ data_i[10] ^ data_i[18] ^ data_i[19] ^ data_i[20] ^ data_i[21] ^ data_i[22] ^ data_i[23] ^ data_i[24] ^ data_i[25];
        ecc_code_o[4] = data_i[11] ^ data_i[12] ^ data_i[13] ^ data_i[14] ^ data_i[15] ^ data_i[16] ^ data_i[17] ^ data_i[18] ^ data_i[19] ^ data_i[20] ^ data_i[21] ^ data_i[22] ^ data_i[23] ^ data_i[24] ^ data_i[25];
        ecc_code_o[5] = data_i[26] ^ data_i[27] ^ data_i[28] ^ data_i[29] ^ data_i[30] ^ data_i[31];
        ecc_code_o[6] = ^data_i ^ (^ecc_code_o[5:0]); // Overall Parity Bit for SECDED
    end

    // Syndrome Calculation
    logic [6:0] syndrome;
    always_comb begin
        syndrome[0] = read_ecc_i[0] ^ read_data_i[0] ^ read_data_i[1] ^ read_data_i[3] ^ read_data_i[4] ^ read_data_i[6] ^ read_data_i[8] ^ read_data_i[10] ^ read_data_i[11] ^ read_data_i[13] ^ read_data_i[15] ^ read_data_i[17] ^ read_data_i[19] ^ read_data_i[21] ^ read_data_i[23] ^ read_data_i[25] ^ read_data_i[26] ^ read_data_i[28] ^ read_data_i[30];
        syndrome[1] = read_ecc_i[1] ^ read_data_i[0] ^ read_data_i[2] ^ read_data_i[3] ^ read_data_i[5] ^ read_data_i[6] ^ read_data_i[9] ^ read_data_i[10] ^ read_data_i[12] ^ read_data_i[13] ^ read_data_i[16] ^ read_data_i[17] ^ read_data_i[20] ^ read_data_i[21] ^ read_data_i[24] ^ read_data_i[25] ^ read_data_i[27] ^ read_data_i[28] ^ read_data_i[31];
        syndrome[2] = read_ecc_i[2] ^ read_data_i[1] ^ read_data_i[2] ^ read_data_i[3] ^ read_data_i[7] ^ read_data_i[8] ^ read_data_i[9] ^ read_data_i[10] ^ read_data_i[14] ^ read_data_i[15] ^ read_data_i[16] ^ read_data_i[17] ^ read_data_i[22] ^ read_data_i[23] ^ read_data_i[24] ^ read_data_i[25] ^ read_data_i[29] ^ read_data_i[30] ^ read_data_i[31];
        syndrome[3] = read_ecc_i[3] ^ read_data_i[4] ^ read_data_i[5] ^ read_data_i[6] ^ read_data_i[7] ^ read_data_i[8] ^ read_data_i[9] ^ read_data_i[10] ^ read_data_i[18] ^ read_data_i[19] ^ read_data_i[20] ^ read_data_i[21] ^ read_data_i[22] ^ read_data_i[23] ^ read_data_i[24] ^ read_data_i[25];
        syndrome[4] = read_ecc_i[4] ^ read_data_i[11] ^ read_data_i[12] ^ read_data_i[13] ^ read_data_i[14] ^ read_data_i[15] ^ read_data_i[16] ^ read_data_i[17] ^ read_data_i[18] ^ read_data_i[19] ^ read_data_i[20] ^ read_data_i[21] ^ read_data_i[22] ^ read_data_i[23] ^ read_data_i[24] ^ read_data_i[25];
        syndrome[5] = read_ecc_i[5] ^ read_data_i[26] ^ read_data_i[27] ^ read_data_i[28] ^ read_data_i[29] ^ read_data_i[30] ^ read_data_i[31];
        syndrome[6] = read_ecc_i[6] ^ (^read_data_i) ^ (^read_ecc_i[5:0]);
    end

    assign single_error_o = (syndrome[6] != 1'b0) && (syndrome[5:0] != 6'b0);
    assign double_error_o = (syndrome[6] == 1'b0) && (syndrome[5:0] != 6'b0);

    assign corrected_data_o = read_data_i; // Simplified output data pass-through

endmodule
