// ============================================================================
// File: rtl/core/rv32i_core.sv
// Description: RV32I 5-Stage RISC-V CPU Core Top Level with AXI4-Lite Master Interface
// Standard: SystemVerilog IEEE 1800-2017
// ============================================================================

module rv32i_core (
    input  logic        clk,
    input  logic        rst_n,

    // Instruction AXI4-Lite Master Interface
    output logic [31:0] instr_addr_o,
    output logic        instr_valid_o,
    input  logic [31:0] instr_rdata_i,
    input  logic        instr_ready_i,

    // Data AXI4-Lite Master Interface
    output logic [31:0] data_addr_o,
    output logic [31:0] data_wdata_o,
    output logic        data_we_o,
    output logic        data_req_o,
    input  logic [31:0] data_rdata_i,
    input  logic        data_ready_i,

    // External Interrupt Line
    input  logic        ext_intr_i
);

    // PC Register
    logic [31:0] pc_q, pc_next;
    logic        pc_stall;

    // IF/ID Pipeline Register
    logic [31:0] if_id_instr;
    logic [31:0] if_id_pc;

    // Decode Signals
    logic [4:0]  rs1_addr, rs2_addr, rd_addr;
    logic [31:0] rs1_data, rs2_data;
    logic [31:0] imm_ext;
    logic        reg_write, mem_to_reg, mem_read, mem_write, alu_src, branch, jump;
    logic [3:0]  alu_op;

    // ID/EX Pipeline Register
    logic [31:0] id_ex_pc, id_ex_rs1_data, id_ex_rs2_data, id_ex_imm;
    logic [4:0]  id_ex_rd;
    logic        id_ex_reg_write, id_ex_mem_to_reg, id_ex_mem_read, id_ex_mem_write, id_ex_alu_src;
    logic [3:0]  id_ex_alu_op;

    // Execute Signals
    logic [31:0] alu_operand_b, alu_result;
    logic        alu_zero;

    // EX/MEM Pipeline Register
    logic [31:0] ex_mem_alu_result, ex_mem_rs2_data;
    logic [4:0]  ex_mem_rd;
    logic        ex_mem_reg_write, ex_mem_mem_to_reg, ex_mem_mem_read, ex_mem_mem_write;

    // MEM/WB Pipeline Register
    logic [31:0] mem_wb_rdata, mem_wb_alu_result;
    logic [4:0]  mem_wb_rd;
    logic        mem_wb_reg_write, mem_wb_mem_to_reg;

    // Final WB Data
    logic [31:0] wb_data;

    // ------------------------------------------------------------------------
    // Fetch Stage
    // ------------------------------------------------------------------------
    assign pc_stall = !instr_ready_i;
    assign pc_next = (branch && alu_zero) ? (id_ex_pc + (id_ex_imm << 1)) :
                     (jump)              ? (pc_q + imm_ext) : (pc_q + 4'd4);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)          pc_q <= 32'h0000_0000;
        else if (!pc_stall)  pc_q <= pc_next;
    end

    assign instr_addr_o  = pc_q;
    assign instr_valid_o = 1'b1;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            if_id_instr <= 32'h0000_0013; // NOP (ADDI x0, x0, 0)
            if_id_pc    <= 32'b0;
        end else if (!pc_stall) begin
            if_id_instr <= instr_rdata_i;
            if_id_pc    <= pc_q;
        end
    end

    // ------------------------------------------------------------------------
    // Decode Stage
    // ------------------------------------------------------------------------
    assign rs1_addr = if_id_instr[19:15];
    assign rs2_addr = if_id_instr[24:20];
    assign rd_addr  = if_id_instr[11:7];

    // Immediate Decoder
    always_comb begin
        case (if_id_instr[6:0])
            7'b0010011, 7'b0000011: imm_ext = {{20{if_id_instr[31]}}, if_id_instr[31:20]}; // I-Type
            7'b0100011:             imm_ext = {{20{if_id_instr[31]}}, if_id_instr[31:25], if_id_instr[11:7]}; // S-Type
            7'b1100011:             imm_ext = {{19{if_id_instr[31]}}, if_id_instr[31], if_id_instr[7], if_id_instr[30:25], if_id_instr[11:8], 1'b0}; // B-Type
            7'b0110111:             imm_ext = {if_id_instr[31:12], 12'b0}; // U-Type (LUI)
            7'b1101111:             imm_ext = {{11{if_id_instr[31]}}, if_id_instr[31], if_id_instr[19:12], if_id_instr[20], if_id_instr[30:21], 1'b0}; // J-Type
            default:                imm_ext = 32'b0;
        endcase
    end

    rv32i_ctrl u_ctrl (
        .opcode_i    (if_id_instr[6:0]),
        .funct3_i    (if_id_instr[14:12]),
        .funct7_i    (if_id_instr[31:24]),
        .reg_write_o (reg_write),
        .mem_to_reg_o(mem_to_reg),
        .mem_read_o  (mem_read),
        .mem_write_o (mem_write),
        .alu_src_o   (alu_src),
        .branch_o    (branch),
        .jump_o      (jump),
        .alu_op_o    (alu_op)
    );

    rv32i_regfile u_regfile (
        .clk        (clk),
        .rst_n      (rst_n),
        .rs1_addr_i (rs1_addr),
        .rs1_data_o (rs1_data),
        .rs2_addr_i (rs2_addr),
        .rs2_data_o (rs2_data),
        .we_i       (mem_wb_reg_write),
        .rd_addr_i  (mem_wb_rd),
        .rd_data_i  (wb_data)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            id_ex_pc        <= 32'b0;
            id_ex_rs1_data  <= 32'b0;
            id_ex_rs2_data  <= 32'b0;
            id_ex_imm       <= 32'b0;
            id_ex_rd        <= 5'b0;
            id_ex_reg_write <= 1'b0;
            id_ex_mem_to_reg<= 1'b0;
            id_ex_mem_read  <= 1'b0;
            id_ex_mem_write <= 1'b0;
            id_ex_alu_src   <= 1'b0;
            id_ex_alu_op    <= 4'b0;
        end else begin
            id_ex_pc        <= if_id_pc;
            id_ex_rs1_data  <= rs1_data;
            id_ex_rs2_data  <= rs2_data;
            id_ex_imm       <= imm_ext;
            id_ex_rd        <= rd_addr;
            id_ex_reg_write <= reg_write;
            id_ex_mem_to_reg<= mem_to_reg;
            id_ex_mem_read  <= mem_read;
            id_ex_mem_write <= mem_write;
            id_ex_alu_src   <= alu_src;
            id_ex_alu_op    <= alu_op;
        end
    end

    // ------------------------------------------------------------------------
    // Execute Stage
    // ------------------------------------------------------------------------
    assign alu_operand_b = (id_ex_alu_src) ? id_ex_imm : id_ex_rs2_data;

    rv32i_alu u_alu (
        .operand_a_i (id_ex_rs1_data),
        .operand_b_i (alu_operand_b),
        .alu_op_i    (id_ex_alu_op),
        .result_o    (alu_result),
        .zero_o      (alu_zero)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ex_mem_alu_result <= 32'b0;
            ex_mem_rs2_data   <= 32'b0;
            ex_mem_rd         <= 5'b0;
            ex_mem_reg_write  <= 1'b0;
            ex_mem_mem_to_reg <= 1'b0;
            ex_mem_mem_read   <= 1'b0;
            ex_mem_mem_write  <= 1'b0;
        end else begin
            ex_mem_alu_result <= alu_result;
            ex_mem_rs2_data   <= id_ex_rs2_data;
            ex_mem_rd         <= id_ex_rd;
            ex_mem_reg_write  <= id_ex_reg_write;
            ex_mem_mem_to_reg <= id_ex_mem_to_reg;
            ex_mem_mem_read   <= id_ex_mem_read;
            ex_mem_mem_write  <= id_ex_mem_write;
        end
    end

    // ------------------------------------------------------------------------
    // Memory Stage
    // ------------------------------------------------------------------------
    assign data_addr_o  = ex_mem_alu_result;
    assign data_wdata_o = ex_mem_rs2_data;
    assign data_we_o    = ex_mem_mem_write;
    assign data_req_o   = ex_mem_mem_read || ex_mem_mem_write;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_wb_rdata      <= 32'b0;
            mem_wb_alu_result <= 32'b0;
            mem_wb_rd         <= 5'b0;
            mem_wb_reg_write  <= 1'b0;
            mem_wb_mem_to_reg <= 1'b0;
        end else begin
            mem_wb_rdata      <= data_rdata_i;
            mem_wb_alu_result <= ex_mem_alu_result;
            mem_wb_rd         <= ex_mem_rd;
            mem_wb_reg_write  <= ex_mem_reg_write;
            mem_wb_mem_to_reg <= ex_mem_mem_to_reg;
        end
    end

    // ------------------------------------------------------------------------
    // Writeback Stage
    // ------------------------------------------------------------------------
    assign wb_data = (mem_wb_mem_to_reg) ? mem_wb_rdata : mem_wb_alu_result;

endmodule
