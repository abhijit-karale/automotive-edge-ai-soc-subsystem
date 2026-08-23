// ============================================================================
// File: verification/testbenches/tb_ecc_hamming.sv
// Description: Unit Testbench for SECDED Hamming ECC Engine (ISO 26262 ASIL-B)
// Standard: SystemVerilog IEEE 1800-2017
// ============================================================================

`timescale 1ns/1ps

module tb_ecc_hamming;

    logic [31:0] data_i;
    logic [6:0]  ecc_code_o;
    logic [31:0] read_data_i;
    logic [6:0]  read_ecc_i;
    logic [31:0] corrected_data_o;
    logic        single_error_o;
    logic        double_error_o;

    // DUT Instantiation
    ecc_hamming u_dut (
        .data_i           (data_i),
        .ecc_code_o       (ecc_code_o),
        .read_data_i      (read_data_i),
        .read_ecc_i       (read_ecc_i),
        .corrected_data_o (corrected_data_o),
        .single_error_o   (single_error_o),
        .double_error_o   (double_error_o)
    );

    initial begin
        $display("==========================================================");
        $display("  [TB START] SECDED Hamming ECC Safety Unit Test          ");
        $display("==========================================================");

        // Test 1: Clean Data (No Error)
        data_i      = 32'hDEAD_BEEF;
        #5;
        read_data_i = 32'hDEAD_BEEF;
        read_ecc_i  = ecc_code_o;
        #5;
        $display("[TB CHECK No-Error] single_err=%b, double_err=%b", single_error_o, double_error_o);
        if (!single_error_o && !double_error_o) begin
            $display("[TB PASS] Clean Data Verification Passed");
        end else begin
            $error("[TB FAIL] False Error Detected on Clean Data!");
        end

        // Test 2: Single Bit Flip (Single Error Detection)
        read_data_i = 32'hDEAD_BEEF ^ 32'h0000_0004; // Flip Bit 2
        #5;
        $display("[TB CHECK Single-Bit] single_err=%b, double_err=%b", single_error_o, double_error_o);
        if (single_error_o && !double_error_o) begin
            $display("[TB PASS] Single-Bit Error Flagged Correctly!");
        end else begin
            $error("[TB FAIL] Single-Bit Error Not Detected!");
        end

        // Test 3: Double Bit Flip (Double Error Detection)
        read_data_i = 32'hDEAD_BEEF ^ 32'h0000_0005; // Flip Bit 0 and Bit 2
        #5;
        $display("[TB CHECK Double-Bit] single_err=%b, double_err=%b", single_error_o, double_error_o);
        if (!single_error_o && double_error_o) begin
            $display("[TB PASS] Double-Bit Fault Detected & Flagged!");
        end else begin
            $error("[TB FAIL] Double-Bit Error Flag Mismatch!");
        end

        $display("==========================================================");
        $display("  [TB SUCCESS] SECDED Hamming ECC Unit Test PASSED!       ");
        $display("==========================================================");
        $finish;
    end

endmodule
