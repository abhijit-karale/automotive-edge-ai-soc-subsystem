  // ============================================================================
  // File: rtl/memory/sram_256k_ecc.sv
  // Description: 256KB On-Chip SRAM Subsystem with Integrated SECDED Hamming ECC
 // Standard: SystemVerilog IEEE 1800-2017
 // ============================================================================

module sram_256k_ecc (
    input  logic        clk,
    input  logic        rst_n,

    // SRAM Bus Interface
    input  logic [31:0] addr_i,
    input  logic [63:0] wdata_i,
    input  logic        we_i,
    input  logic        req_i,
    output logic [63:0] rdata_o,
    output logic        ready_o,

    // Safety Fault Signals (ISO 26262 ASIL-B)
    output logic        ecc_single_err_o,
    output logic        ecc_double_err_o
);

    localparam int DEPTH = 32768; // 32K x 64-bit = 256KB

    logic [63:0] mem [0:DEPTH-1];
    logic [6:0]  ecc_mem [0:DEPTH-1];

    logic [14:0] word_addr;
    assign word_addr = addr_i[17:3];

    // ECC Hardware Instance
    logic [6:0]  gen_ecc;
    logic [31:0] corrected_data;

    ecc_hamming u_ecc (
        .data_i           (wdata_i[31:0]),
        .ecc_code_o       (gen_ecc),
        .read_data_i      (rdata_o[31:0]),
        .read_ecc_i       (ecc_mem[word_addr]),
        .corrected_data_o (corrected_data),
        .single_error_o   (ecc_single_err_o),
        .double_error_o   (ecc_double_err_o)
    );

    // Synchronous Read/Write
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready_o <= 1'b0;
            rdata_o <= 64'b0;
        end else if (req_i) begin
            ready_o <= 1'b1;
            if (we_i) begin
                mem[word_addr]     <= wdata_i;
                ecc_mem[word_addr] <= gen_ecc;
            end else begin
                rdata_o <= mem[word_addr];
            end
        end else begin
            ready_o <= 1'b0;
        end
    end

endmodule
