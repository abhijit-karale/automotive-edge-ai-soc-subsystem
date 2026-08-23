// ============================================================================
// File: rtl/accelerator/accel_csr_regs.sv
// Description: Control & Status Registers (CSRs) for AI Accelerator
// Standard: SystemVerilog IEEE 1800-2017
// ============================================================================

module accel_csr_regs (
    input  logic        clk,
    input  logic        rst_n,

    // Bus Slave Interface (32-bit Register Access)
    input  logic [5:0]  reg_addr_i,
    input  logic [31:0] reg_wdata_i,
    input  logic        reg_write_i,
    input  logic        reg_read_i,
    output logic [31:0] reg_rdata_o,

    // Hardware Internal Control Interfaces
    input  logic        accel_busy_i,
    input  logic        accel_done_i,
    input  logic        accel_overflow_i,
    input  logic        accel_bus_err_i,

    // Control Outputs to Accelerator Hardware
    output logic        start_pulse_o,
    output logic        soft_reset_o,
    output logic        int_en_o,
    output logic        dma_en_o,
    output logic [2:0]  mode_o,
    output logic [31:0] src_addr_o,
    output logic [31:0] dst_addr_o,
    output logic [15:0] dim_m_o,
    output logic [15:0] dim_n_o,
    output logic [7:0]  scale_o,
    output logic [7:0]  shift_o,
    output logic        relu_en_o,
    output logic        intr_line_o
);

    // CSR Register Definitions
    logic [31:0] reg_ctrl_q;
    logic [31:0] reg_status_q;
    logic [31:0] reg_src_addr_q;
    logic [31:0] reg_dst_addr_q;
    logic [31:0] reg_dim_q;
    logic [31:0] reg_quant_q;

    logic start_pulse_d;

    // Bit Field Extract
    assign int_en_o     = reg_ctrl_q[1];
    assign soft_reset_o = reg_ctrl_q[2];
    assign mode_o       = reg_ctrl_q[5:3];
    assign dma_en_o     = reg_ctrl_q[8];

    assign src_addr_o   = reg_src_addr_q;
    assign dst_addr_o   = reg_dst_addr_q;

    assign dim_n_o      = reg_dim_q[15:0];
    assign dim_m_o      = reg_dim_q[31:16];

    assign scale_o      = reg_quant_q[7:0];
    assign shift_o      = reg_quant_q[15:8];
    assign relu_en_o    = reg_quant_q[16];

    assign start_pulse_o = start_pulse_d;

    // Interrupt line generation
    assign intr_line_o   = int_en_o && (reg_status_q[1] || reg_status_q[2] || reg_status_q[3]);

    // Register Write Logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_ctrl_q     <= 32'b0;
            reg_status_q   <= 32'b0;
            reg_src_addr_q <= 32'b0;
            reg_dst_addr_q <= 32'b0;
            reg_dim_q      <= 32'b0;
            reg_quant_q    <= 32'b0;
            start_pulse_d  <= 1'b0;
        end else begin
            start_pulse_d  <= 1'b0; // Self-clearing pulse

            // Hardware Status Updates
            reg_status_q[0] <= accel_busy_i;
            if (accel_done_i)     reg_status_q[1] <= 1'b1;
            if (accel_overflow_i) reg_status_q[2] <= 1'b1;
            if (accel_bus_err_i)  reg_status_q[3] <= 1'b1;

            // Bus Write Writes
            if (reg_write_i) begin
                case (reg_addr_i)
                    6'h00: begin // ACCEL_CTRL
                        reg_ctrl_q <= reg_wdata_i;
                        if (reg_wdata_i[0]) start_pulse_d <= 1'b1; // Trigger START
                    end
                    6'h04: begin // ACCEL_STATUS (Write-1-to-Clear for bits 1, 2, 3)
                        if (reg_wdata_i[1]) reg_status_q[1] <= 1'b0;
                        if (reg_wdata_i[2]) reg_status_q[2] <= 1'b0;
                        if (reg_wdata_i[3]) reg_status_q[3] <= 1'b0;
                    end
                    6'h08: reg_src_addr_q <= reg_wdata_i;
                    6'h0C: reg_dst_addr_q <= reg_wdata_i;
                    6'h10: reg_dim_q      <= reg_wdata_i;
                    6'h14: reg_quant_q    <= reg_wdata_i;
                    default: ;
                endcase
            end
        end
    end

    // Register Read Logic
    always_comb begin
        case (reg_addr_i)
            6'h00: reg_rdata_o = reg_ctrl_q;
            6'h04: reg_rdata_o = reg_status_q;
            6'h08: reg_rdata_o = reg_src_addr_q;
            6'h0C: reg_rdata_o = reg_dst_addr_q;
            6'h10: reg_rdata_o = reg_dim_q;
            6'h14: reg_rdata_o = reg_quant_q;
            default: reg_rdata_o = 32'b0;
        endcase
    end

endmodule
