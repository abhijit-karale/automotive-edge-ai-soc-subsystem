// ============================================================================
// File: verification/testbenches/tb_accel_mac_array.sv
// Description: Unit Testbench for 4x4 INT8 Systolic Array MAC Hardware Engine
// Standard: SystemVerilog IEEE 1800-2017
// ============================================================================

`timescale 1ns/1ps

module tb_accel_mac_array;

    parameter int ARRAY_SIZE = 4;

    logic        clk;
    logic        rst_n;
    logic        enable_i;
    logic        clear_accum_i;

    logic signed [7:0] weight_matrix_i [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
    logic signed [7:0] input_matrix_i  [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];

    logic signed [31:0] accum_matrix_o [0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
    logic               mac_done_o;

    // DUT Instantiation
    accel_mac_array #(
        .ARRAY_SIZE(ARRAY_SIZE)
    ) u_dut (
        .clk             (clk),
        .rst_n           (rst_n),
        .enable_i        (enable_i),
        .clear_accum_i   (clear_accum_i),
        .weight_matrix_i (weight_matrix_i),
        .input_matrix_i  (input_matrix_i),
        .accum_matrix_o  (accum_matrix_o),
        .mac_done_o      (mac_done_o)
    );

    // 100 MHz Clock Generation
    always #5 clk = ~clk;

    // Test Sequence
    initial begin
        clk           = 0;
        rst_n         = 0;
        enable_i      = 0;
        clear_accum_i = 0;

        #20;
        rst_n = 1;
        #10;

        $display("==========================================================");
        $display("  [TB START] INT8 Systolic Array MAC Engine Unit Test     ");
        $display("==========================================================");

        // Load 4x4 Weight Matrix W and Input Matrix X
        // W = [[1, 2, 3, 4], [5, 6, 7, 8], [1, 1, 1, 1], [2, 0, 1, 0]]
        // X = [[1, 0, 1, 0], [0, 1, 0, 1], [1, 1, 0, 0], [0, 0, 1, 1]]
        weight_matrix_i[0][0] = 8'sd1; weight_matrix_i[0][1] = 8'sd2; weight_matrix_i[0][2] = 8'sd3; weight_matrix_i[0][3] = 8'sd4;
        weight_matrix_i[1][0] = 8'sd5; weight_matrix_i[1][1] = 8'sd6; weight_matrix_i[1][2] = 8'sd7; weight_matrix_i[1][3] = 8'sd8;
        weight_matrix_i[2][0] = 8'sd1; weight_matrix_i[2][1] = 8'sd1; weight_matrix_i[2][2] = 8'sd1; weight_matrix_i[2][3] = 8'sd1;
        weight_matrix_i[3][0] = 8'sd2; weight_matrix_i[3][1] = 8'sd0; weight_matrix_i[3][2] = 8'sd1; weight_matrix_i[3][3] = 8'sd0;

        input_matrix_i[0][0] = 8'sd1; input_matrix_i[0][1] = 8'sd0; input_matrix_i[0][2] = 8'sd1; input_matrix_i[0][3] = 8'sd0;
        input_matrix_i[1][0] = 8'sd0; input_matrix_i[1][1] = 8'sd1; input_matrix_i[1][2] = 8'sd0; input_matrix_i[1][3] = 8'sd1;
        input_matrix_i[2][0] = 8'sd1; input_matrix_i[2][1] = 8'sd1; input_matrix_i[2][2] = 8'sd0; input_matrix_i[2][3] = 8'sd0;
        input_matrix_i[3][0] = 8'sd0; input_matrix_i[3][1] = 8'sd0; input_matrix_i[3][2] = 8'sd1; input_matrix_i[3][3] = 8'sd1;

        // Trigger MAC
        enable_i = 1'b1;
        wait(mac_done_o);
        #10;
        enable_i = 1'b0;

        $display("[TB CHECK] MAC Output Accumulator [0][0] = %d (Expected: 4)", accum_matrix_o[0][0]);
        $display("[TB CHECK] MAC Output Accumulator [0][1] = %d (Expected: 5)", accum_matrix_o[0][1]);
        $display("[TB CHECK] MAC Output Accumulator [1][0] = %d (Expected: 12)", accum_matrix_o[1][0]);
        $display("[TB CHECK] MAC Output Accumulator [1][1] = %d (Expected: 13)", accum_matrix_o[1][1]);

        if (accum_matrix_o[0][0] == 4 && accum_matrix_o[0][1] == 5 && accum_matrix_o[1][0] == 12) begin
            $display("==========================================================");
            $display("  [TB PASS] INT8 Systolic Array MAC Unit Test PASSED!     ");
            $display("==========================================================");
        end else begin
            $error("[TB FAIL] MAC Matrix Multiplication Mismatch!");
        end

        #20;
        $finish;
    end

endmodule
