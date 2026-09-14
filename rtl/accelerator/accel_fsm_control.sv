 // ============================================================================
// File: rtl/accelerator/accel_fsm_control.sv
// Description: AI Accelerator Control State Machine
// Standard: SystemVerilog IEEE 1800-2017
// ============================================================================

module accel_fsm_control (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        start_i,
    input  logic        dma_rd_done_i,
    input  logic        dma_wr_done_i,
    input  logic        mac_done_i,
    output logic [2:0]  state_o,
    output logic        accel_busy_o,
    output logic        accel_done_o
);
    typedef enum logic [2:0] {
        ST_IDLE         = 3'b000,
        ST_FETCH_WEIGHT = 3'b001,
        ST_FETCH_INPUT  = 3'b010,
        ST_COMPUTE_MAC  = 3'b011,
        ST_QUANT_ACT    = 3'b100,
        ST_WRITE_BACK   = 3'b101
    } state_e;

    state_e state_q, state_d;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) state_q <= ST_IDLE;
        else        state_q <= state_d;
    end

    always_comb begin
        state_d      = state_q;
        accel_busy_o = 1'b1;
        accel_done_o = 1'b0;

        case (state_q)
            ST_IDLE: begin
                accel_busy_o = 1'b0;
                if (start_i) state_d = ST_FETCH_WEIGHT;
            end
            ST_FETCH_WEIGHT: if (dma_rd_done_i) state_d = ST_FETCH_INPUT;
            ST_FETCH_INPUT:  if (dma_rd_done_i) state_d = ST_COMPUTE_MAC;
            ST_COMPUTE_MAC:  if (mac_done_i)    state_d = ST_QUANT_ACT;
            ST_QUANT_ACT:    state_d = ST_WRITE_BACK;
            ST_WRITE_BACK:   begin
                if (dma_wr_done_i) begin
                    accel_done_o = 1'b1;
                    state_d      = ST_IDLE;
                end
            end
            default: state_d = ST_IDLE;
        endcase
    end
    assign state_o = state_q;
endmodule
