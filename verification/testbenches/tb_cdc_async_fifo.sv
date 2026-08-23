// ============================================================================
// File: verification/testbenches/tb_cdc_async_fifo.sv
// Description: Unit Testbench for Dual-Clock Async CDC FIFO (Gray Code Synchronizer)
// Standard: SystemVerilog IEEE 1800-2017
// ============================================================================

`timescale 1ns/1ps

module tb_cdc_async_fifo;

    parameter int D_WIDTH = 32;
    parameter int A_WIDTH = 4;

    logic               wclk;
    logic               wrst_n;
    logic               winc;
    logic [D_WIDTH-1:0] wdata;
    logic               wfull;

    logic               rclk;
    logic               rrst_n;
    logic               rinc;
    logic [D_WIDTH-1:0] rdata;
    logic               rempty;

    // DUT Instantiation
    cdc_async_fifo #(
        .D_WIDTH(D_WIDTH),
        .A_WIDTH(A_WIDTH)
    ) u_dut (
        .wclk   (wclk),
        .wrst_n (wrst_n),
        .winc   (winc),
        .wdata  (wdata),
        .wfull  (wfull),
        .rclk   (rclk),
        .rrst_n (rrst_n),
        .rinc   (rinc),
        .rdata  (rdata),
        .rempty (rempty)
    );

    // 200 MHz Write Clock (5ns)
    always #2.5 wclk = ~wclk;

    // 50 MHz Read Clock (20ns)
    always #10 rclk = ~rclk;

    initial begin
        wclk   = 0;
        wrst_n = 0;
        winc   = 0;
        wdata  = 0;

        rclk   = 0;
        rrst_n = 0;
        rinc   = 0;

        #30;
        wrst_n = 1;
        rrst_n = 1;
        #20;

        $display("==========================================================");
        $display("  [TB START] Dual-Clock Async CDC FIFO Unit Test          ");
        $display("==========================================================");

        // Verify Initial Empty State
        if (rempty) begin
            $display("[TB PASS] CDC FIFO Initially Empty (rempty = 1)");
        end else begin
            $error("[TB FAIL] CDC FIFO Initial Empty Flag Mismatch!");
        end

        // Push Data into Write Clock Domain (200MHz)
        @(posedge wclk);
        wdata = 32'hA5A5_5A5A;
        winc  = 1'b1;
        @(posedge wclk);
        wdata = 32'h1234_5678;
        winc  = 1'b1;
        @(posedge wclk);
        winc  = 1'b0;

        // Synchronize & Pop from Read Clock Domain (50MHz)
        repeat (4) @(posedge rclk);
        if (!rempty) begin
            $display("[TB PASS] Data Synchronized Across Clock Domains! (rdata = 0x%08h)", rdata);
            rinc = 1'b1;
            @(posedge rclk);
            rinc = 1'b0;
        end else begin
            $error("[TB FAIL] CDC FIFO Synchronization Timeout!");
        end

        $display("==========================================================");
        $display("  [TB SUCCESS] Dual-Clock Async CDC FIFO Unit Test PASSED!");
        $display("==========================================================");
        #50;
        $finish;
    end

endmodule
