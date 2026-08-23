// ============================================================================
// File: rtl/accelerator/accel_mac_array.sv
// Description: 4x4 INT8 Systolic Array MAC Hardware Engine
// Standard: SystemVerilog IEEE 1800-2017
// ============================================================================

module accel_mac_array #(
    parameter int ARRAY_SIZE = 4
)(
    input  logic        clk,
    input  logic        rst_n,
    input  logic        enable_i,
    input  logic        clear_accum_i,

    // Weight and Input Feature Inputs (INT8)
    input  logic signed [7:0] weight_matrix_i [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1],
    input  logic signed [7:0] input_matrix_i  [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1],

    // Output Accumulators (INT32)
    output logic signed [31:0] accum_matrix_o [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1],
    output logic               mac_done_o
);

    logic signed [31:0] accum_q [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
    logic [2:0]         step_cnt_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            step_cnt_q <= '0;
            mac_done_o <= 1'b0;
            for (int i = 0; i < ARRAY_SIZE; i++) begin
                for (int j = 0; j < ARRAY_SIZE; j++) begin
                    accum_q[i][j] <= '0;
                end
            end
        end else if (clear_accum_i) begin
            step_cnt_q <= '0;
            mac_done_o <= 1'b0;
            for (int i = 0; i < ARRAY_SIZE; i++) begin
                for (int j = 0; j < ARRAY_SIZE; j++) begin
                    accum_q[i][j] <= '0;
                end
            end
        end else if (enable_i) begin
            // 4-step Multiply-Accumulate Dot Product Computation
            for (int i = 0; i < ARRAY_SIZE; i++) begin
                for (int j = 0; j < ARRAY_SIZE; j++) begin
                    accum_q[i][j] <= accum_q[i][j] + (weight_matrix_i[i][step_cnt_q] * input_matrix_i[step_cnt_q][j]);
                end
            end

            if (step_cnt_q == ARRAY_SIZE - 1) begin
                mac_done_o <= 1'b1;
            end else begin
                step_cnt_q <= step_cnt_q + 1'b1;
            end
        end
    end

    assign accum_matrix_o = accum_q;

endmodule
