// ============================================================================
// File: rtl/core/rv32i_alu.sv
// Description: RV32I 32-bit Arithmetic Logic Unit (ALU)
// Standard: SystemVerilog IEEE 1800-2017
// ============================================================================

module rv32i_alu (
    input  logic [31:0] operand_a_i,
    input  logic [31:0] operand_b_i,
    input  logic [3:0]  alu_op_i,

    output logic [31:0] result_o,
    output logic        zero_o
);

    always_comb begin
        case (alu_op_i)
            4'b0000: result_o = operand_a_i + operand_b_i;                      // ADD
            4'b0001: result_o = operand_a_i - operand_b_i;                      // SUB
            4'b0010: result_o = operand_a_i << operand_b_i[4:0];                // SLL
            4'b0011: result_o = ($signed(operand_a_i) < $signed(operand_b_i)) ? 32'b1 : 32'b0; // SLT
            4'b0100: result_o = (operand_a_i < operand_b_i) ? 32'b1 : 32'b0;    // SLTU
            4'b0101: result_o = operand_a_i ^ operand_b_i;                      // XOR
            4'b0110: result_o = operand_a_i >> operand_b_i[4:0];                // SRL
            4'b0111: result_o = $signed(operand_a_i) >>> operand_b_i[4:0];      // SRA
            4'b1000: result_o = operand_a_i | operand_b_i;                      // OR
            4'b1001: result_o = operand_a_i & operand_b_i;                      // AND
            4'b1010: result_o = operand_b_i;                                    // PASS B (LUI)
            default: result_o = 32'b0;
        endcase
    end

    assign zero_o = (result_o == 32'b0);

endmodule
