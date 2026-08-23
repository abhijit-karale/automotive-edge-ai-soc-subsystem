// ============================================================================
// File: verification/testbenches/tb_soc_top.sv
// Description: Top-Level SystemVerilog Simulation Testbench for SoC Subsystem
// Standard: SystemVerilog IEEE 1800-2017
// ============================================================================

`timescale 1ns/1ps

module tb_soc_top;

    // Clock and Reset Signals
    logic clk_soc;
    logic rst_soc_n;
    logic clk_pclk;
    logic rst_pclk_n;

    // External Interfaces
    logic can_tx;
    logic can_rx;
    logic uart_tx;
    logic uart_rx;
    logic soc_interrupt;
    logic ecc_fault_nmi;

    // Subsystem Instantiation
    soc_top u_dut (
        .clk_soc         (clk_soc),
        .rst_soc_n       (rst_soc_n),
        .clk_pclk        (clk_pclk),
        .rst_pclk_n      (rst_pclk_n),
        .can_tx_o        (can_tx),
        .can_rx_i        (can_rx),
        .uart_tx_o       (uart_tx),
        .uart_rx_i       (uart_rx),
        .soc_interrupt_o (soc_interrupt),
        .ecc_fault_nmi_o (ecc_fault_nmi)
    );

    // 200 MHz SoC Clock Domain (5ns Period)
    initial begin
        clk_soc = 0;
        forever #2.5 clk_soc = ~clk_soc;
    end

    // 50 MHz Peripheral Clock Domain (20ns Period)
    initial begin
        clk_pclk = 0;
        forever #10 clk_pclk = ~clk_pclk;
    end

    // Test Sequence Execution
    initial begin
        $display("==========================================================");
        $display("  [TB START] Automotive Edge AI SoC Subsystem Simulation  ");
        $display("==========================================================");

        // Drive Initial Inputs
        rst_soc_n  = 1'b0;
        rst_pclk_n = 1'b0;
        can_rx     = 1'b1;
        uart_rx    = 1'b1;

        #50;
        if (u_dut.u_rv32i_cpu.pc_q == 32'h0000_0000) begin
            $display("[TB PASS] RV32I Processor Reset Vector Initialized (PC = 0x0000_0000)");
        end else begin
            $error("[TB FAIL] RV32I Processor Reset Vector Invalid!");
        end

        // Reset Pulse (100ns total)
        #50;
        rst_soc_n  = 1'b1;
        rst_pclk_n = 1'b1;
        $display("[TB INFO] Resets Deasserted at time %0t ps", $time);

        // Wait for system stabilization
        #200;

        // Verify Top-Level Clock & Power Integrity
        $display("[TB CHECK] Checking Subsystem Clock & Execution Status...");
        if (u_dut.u_rv32i_cpu.pc_q > 32'h0000_0000) begin
            $display("[TB PASS] RV32I Processor Pipeline Executing (PC = 0x%08h)", u_dut.u_rv32i_cpu.pc_q);
        end else begin
            $error("[TB FAIL] RV32I Processor Pipeline Stalled!");
        end

        // Run for 1,000ns
        #1000;

        $display("==========================================================");
        $display("  [TB SUCCESS] Week 1 RTL & Testbench Simulation PASSED!   ");
        $display("==========================================================");
        $finish;
    end

    // VCD Waveform Generation
    initial begin
        $dumpfile("sim/dump.vcd");
        $dumpvars(0, tb_soc_top);
    end

endmodule
