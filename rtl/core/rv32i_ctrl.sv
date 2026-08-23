// ============================================================================
// File: rtl/core/rv32i_ctrl.sv
// Description: RV32I Main Control Decoder Unit
// Standard: SystemVerilog IEEE 1800-2017
// ============================================================================

module rv32i_ctrl (
    input  logic [6:0] opcode_i,
    input  logic [2:0] funct3_i,
    input  logic [7:0] funct7_i,

    output logic       reg_write_o,
    output logic       mem_to_reg_o,
    output logic       mem_read_o,
    output logic       mem_write_o,
    output logic       alu_src_o,
    output logic       branch_o,
    output logic       jump_o,
    output logic [3:0] alu_op_o
);

    always_comb begin
        reg_write_o  = 1'b0;
        mem_to_reg_o = 1'b0;
        mem_read_o   = 1'b0;
        mem_write_o  = 1'b0;
        alu_src_o    = 1'b0;
        branch_o     = 1'b0;
        jump_o       = 1'b0;
        alu_op_o     = 4'b0000; // ADD

        case (opcode_i)
            // R-Type Instructions (ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND)
            7'b0110011: begin
                reg_write_o = 1'b1;
                case (funct3_i)
                    3'b000: alu_op_o = (funct7_i[5]) ? 4'b0001 : 4'b0000; // SUB : ADD
                    3'b001: alu_op_o = 4'b0010; // SLL
                    3'b010: alu_op_o = 4'b0011; // SLT
                    3'b011: alu_op_o = 4'b0100; // SLTU
                    3'b100: alu_op_o = 4'b0101; // XOR
                    3'b101: alu_op_o = (funct7_i[5]) ? 4'b0111 : 4'b0110; // SRA : SRL
                    3'b110: alu_op_o = 4'b1000; // OR
                    3'b111: alu_op_o = 4'b1001; // AND
                endcase
            end

            // I-Type ALU (ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI)
            7'b0010011: begin
                reg_write_o = 1'b1;
                alu_src_o   = 1'b1;
                case (funct3_i)
                    3'b000: alu_op_o = 4'b0000; // ADDI
                    3'b010: alu_op_o = 4'b0011; // SLTI
                    3'b011: alu_op_o = 4'b0100; // SLTIU
                    3'b100: alu_op_o = 4'b0101; // XORI
                    3'b110: alu_op_o = 4'b1000; // ORI
                    3'b111: alu_op_o = 4'b1001; // ANDI
                    3'b001: alu_op_o = 4'b0010; // SLLI
                    3'b101: alu_op_o = (funct7_i[5]) ? 4'b0111 : 4'b0110; // SRAI : SRLI
                endcase
            end

            // Load Instructions (LW, LH, LB, etc.)
            7'b0000011: begin
                reg_write_o  = 1'b1;
                mem_to_reg_o = 1'b1;
                mem_read_o   = 1'b1;
                alu_src_o    = 1'b1;
                alu_op_o     = 4'b0000; // Address Calc (ADD)
            end

            // Store Instructions (SW, SH, SB)
            7'b0100011: begin
                mem_write_o = 1'b1;
                alu_src_o   = 1'b1;
                alu_op_o    = 4'b0000; // Address Calc (ADD)
            end

            // Branch Instructions (BEQ, BNE, BLT, BGE, BLTU, BGEU)
            7'b1100011: begin
                branch_o = 1'b1;
                alu_op_o = 4'b0001; // SUB for comparison
            end

            // JAL
            7'b1101111: begin
                jump_o      = 1'b1;
                reg_write_o = 1'b1;
            end

            // LUI
            7'b0110111: begin
                reg_write_o = 1'b1;
                alu_src_o   = 1'b1;
                alu_op_o    = 4'b1010; // Pass Immediate
            end

            default: ;
        endcase
    end

endmodule
