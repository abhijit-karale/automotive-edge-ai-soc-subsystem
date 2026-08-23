// ============================================================================
// File: rtl/core/rv32i_regfile.sv
// Description: RV32I 32x32-bit Register File with Dual Read & Single Write Ports
// Standard: SystemVerilog IEEE 1800-2017
// ============================================================================

module rv32i_regfile (
    input  logic        clk,
    input  logic        rst_n,

    // Read Port 1
    input  logic [4:0]  rs1_addr_i,
    output logic [31:0] rs1_data_o,

    // Read Port 2
    input  logic [4:0]  rs2_addr_i,
    output logic [31:0] rs2_data_o,

    // Write Port
    input  logic        we_i,
    input  logic [4:0]  rd_addr_i,
    input  logic [31:0] rd_data_i
);

    logic [31:0] rf [31:1]; // x0 is hardwired to zero

    // Async Read with x0 check
    assign rs1_data_o = (rs1_addr_i == 5'b0) ? 32'b0 : rf[rs1_addr_i];
    assign rs2_data_o = (rs2_addr_i == 5'b0) ? 32'b0 : rf[rs2_addr_i];

    // Synchronous Write
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 1; i < 32; i++) begin
                rf[i] <= 32'b0;
            end
        end else if (we_i && (rd_addr_i != 5'b0)) begin
            rf[rd_addr_i] <= rd_data_i;
        end
    end

endmodule
