 // ============================================================================
 // File: rtl/accelerator/accel_quantizer.sv
 // Description: Quantizer & Activation (ReLU / Pass-through) Unit
 // Standard: SystemVerilog IEEE 1800-2017
 // ============================================================================

module accel_quantizer #(
    parameter int ARRAY_SIZE = 4
)(
    input  logic        clk,
    input  logic        rst_n,
    input  logic        enable_i,

    input  logic [7:0]  scale_i,
    input  logic [7:0]  shift_i,
    input  logic        relu_en_i,

    input  logic signed [31:0] accum_matrix_i [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1],
    output logic signed [31:0] quant_matrix_o [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1],
    output logic               quant_done_o
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            quant_done_o <= 1'b0;
            for (int i = 0; i < ARRAY_SIZE; i++) begin
                for (int j = 0; j < ARRAY_SIZE; j++) begin
                    quant_matrix_o[i][j] <= '0;
                end
            end
        end else if (enable_i) begin
            for (int i = 0; i < ARRAY_SIZE; i++) begin
                for (int j = 0; j < ARRAY_SIZE; j++) begin
                    logic signed [63:0] scaled_temp;
                    logic signed [31:0] shifted_temp;

                    scaled_temp  = accum_matrix_i[i][j] * scale_i;
                    shifted_temp = scaled_temp >>> shift_i;

                    if (relu_en_i && shifted_temp < 0) begin
                        quant_matrix_o[i][j] <= 32'b0;
                    end else begin
                        quant_matrix_o[i][j] <= shifted_temp;
                    end
                end
            end
            quant_done_o <= 1'b1;
        end else begin
            quant_done_o <= 1'b0;
        end
    end

endmodule
