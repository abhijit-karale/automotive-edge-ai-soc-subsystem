// ============================================================================
// File: rtl/top/soc_top.sv
// Description: Automotive Edge Sensor & AI Accelerator SoC Subsystem Top-Level
// Standard: SystemVerilog IEEE 1800-2017
// ============================================================================

module soc_top (
    input  logic        clk_soc,    // 200 MHz High-Speed SoC Clock Domain
    input  logic        rst_soc_n,  // Active-Low SoC Reset

    input  logic        clk_pclk,   // 50 MHz Low-Speed Peripheral Clock Domain
    input  logic        rst_pclk_n, // Active-Low Peripheral Reset

    // External Automotive Pins
    output logic        can_tx_o,
    input  logic        can_rx_i,
    output logic        uart_tx_o,
    input  logic        uart_rx_i,

    // Subsystem Interrupt Line Output
    output logic        soc_interrupt_o,
    output logic        ecc_fault_nmi_o
);

    // ------------------------------------------------------------------------
    // RV32I Core AXI4 Signals
    // ------------------------------------------------------------------------
    logic [31:0] core_instr_addr;
    logic        core_instr_valid, core_instr_ready;
    logic [31:0] core_instr_rdata;

    logic [31:0] core_data_addr, core_data_wdata;
    logic        core_data_we, core_data_req, core_data_ready;
    logic [31:0] core_data_rdata;

    // ------------------------------------------------------------------------
    // AXI Crossbar Bus Interconnect Signals
    // ------------------------------------------------------------------------
    logic [31:0] s0_awaddr, s0_araddr;
    logic [63:0] s0_wdata,  s0_rdata;
    logic        s0_awvalid, s0_awready, s0_wvalid, s0_wready, s0_bvalid, s0_bready;
    logic        s0_arvalid, s0_arready, s0_rvalid, s0_rready;
    logic [1:0]  s0_bresp;

    logic [31:0] s1_awaddr, s1_araddr;
    logic [63:0] s1_wdata,  s1_rdata;
    logic        s1_awvalid, s1_awready, s1_wvalid, s1_wready, s1_bvalid, s1_bready;
    logic        s1_arvalid, s1_arready, s1_rvalid, s1_rready;
    logic [1:0]  s1_bresp;

    logic [31:0] s2_awaddr, s2_araddr;
    logic [63:0] s2_wdata,  s2_rdata;
    logic        s2_awvalid, s2_awready, s2_wvalid, s2_wready, s2_bvalid, s2_bready;
    logic        s2_arvalid, s2_arready, s2_rvalid, s2_rready;
    logic [1:0]  s2_bresp;

    // ------------------------------------------------------------------------
    // APB Bus Signals
    // ------------------------------------------------------------------------
    logic [31:0] apb_paddr, apb_pwdata, apb_prdata;
    logic        apb_psel, apb_penable, apb_pwrite, apb_pready, apb_pslverr;

    // ------------------------------------------------------------------------
    // Accelerator Signals
    // ------------------------------------------------------------------------
    logic        accel_start, accel_busy, accel_done, accel_soft_reset;
    logic        accel_int_en, accel_dma_en, accel_intr_line;
    logic [2:0]  accel_mode, accel_fsm_state;
    logic [31:0] accel_src_addr, accel_dst_addr;
    logic [15:0] accel_dim_m, accel_dim_n;
    logic [7:0]  accel_scale, accel_shift;
    logic        accel_relu_en;

    // Interrupts
    logic        can_intr, uart_intr;

    // ------------------------------------------------------------------------
    // RV32I Processor Core Instance
    // ------------------------------------------------------------------------
    rv32i_core u_rv32i_cpu (
        .clk            (clk_soc),
        .rst_n          (rst_soc_n),
        .instr_addr_o   (core_instr_addr),
        .instr_valid_o  (core_instr_valid),
        .instr_rdata_i  (32'h0000_0013), // NOP Instruction stub
        .instr_ready_i  (1'b1),
        .data_addr_o    (core_data_addr),
        .data_wdata_o   (core_data_wdata),
        .data_we_o      (core_data_we),
        .data_req_o     (core_data_req),
        .data_rdata_i   (core_data_rdata),
        .data_ready_i   (core_data_ready),
        .ext_intr_i     (accel_intr_line || can_intr || uart_intr)
    );

    // ------------------------------------------------------------------------
    // 64-bit AXI4 Crossbar Interconnect
    // ------------------------------------------------------------------------
    axi4_crossbar u_axi_crossbar (
        .clk        (clk_soc),
        .rst_n      (rst_soc_n),

        // M0: RV32I Core Data Bus
        .m0_awaddr  (core_data_addr),
        .m0_awvalid (core_data_req && core_data_we),
        .m0_awready (),
        .m0_wdata   ({32'b0, core_data_wdata}),
        .m0_wvalid  (core_data_req && core_data_we),
        .m0_wready  (),
        .m0_bresp   (),
        .m0_bvalid  (),
        .m0_bready  (1'b1),
        .m0_araddr  (core_data_addr),
        .m0_arvalid (core_data_req && !core_data_we),
        .m0_arready (),
        .m0_rdata   (),
        .m0_rvalid  (),
        .m0_rready  (1'b1),

        // M1: DMA Engine Interface (Stubbed)
        .m1_awaddr  (32'b0), .m1_awvalid (1'b0), .m1_awready (),
        .m1_wdata   (64'b0), .m1_wvalid  (1'b0), .m1_wready  (),
        .m1_bresp   (),      .m1_bvalid  (),     .m1_bready  (1'b1),
        .m1_araddr  (32'b0), .m1_arvalid (1'b0), .m1_arready (),
        .m1_rdata   (),      .m1_rvalid  (),     .m1_rready  (1'b1),

        // S0: SRAM 256KB Memory Subsystem
        .s0_awaddr  (s0_awaddr),  .s0_awvalid (s0_awvalid), .s0_awready (s0_awready),
        .s0_wdata   (s0_wdata),   .s0_wvalid  (s0_wvalid),  .s0_wready  (s0_wready),
        .s0_bresp   (2'b00),      .s0_bvalid  (s0_bvalid),  .s0_bready  (s0_bready),
        .s0_araddr  (s0_araddr),  .s0_arvalid (s0_arvalid), .s0_arready (s0_arready),
        .s0_rdata   (s0_rdata),   .s0_rvalid  (s0_rvalid),  .s0_rready  (s0_rready),

        // S1: AI Accelerator CSRs
        .s1_awaddr  (s1_awaddr),  .s1_awvalid (s1_awvalid), .s1_awready (s1_awready),
        .s1_wdata   (s1_wdata),   .s1_wvalid  (s1_wvalid),  .s1_wready  (s1_wready),
        .s1_bresp   (2'b00),      .s1_bvalid  (s1_bvalid),  .s1_bready  (s1_bready),
        .s1_araddr  (s1_araddr),  .s1_arvalid (s1_arvalid), .s1_arready (s1_arready),
        .s1_rdata   (s1_rdata),   .s1_rvalid  (s1_rvalid),  .s1_rready  (s1_rready),

        // S2: AXI-to-APB Bridge
        .s2_awaddr  (s2_awaddr),  .s2_awvalid (s2_awvalid), .s2_awready (s2_awready),
        .s2_wdata   (s2_wdata),   .s2_wvalid  (s2_wvalid),  .s2_wready  (s2_wready),
        .s2_bresp   (2'b00),      .s2_bvalid  (s2_bvalid),  .s2_bready  (s2_bready),
        .s2_araddr  (s2_araddr),  .s2_arvalid (s2_arvalid), .s2_arready (s2_arready),
        .s2_rdata   (s2_rdata),   .s2_rvalid  (s2_rvalid),  .s2_rready  (s2_rready)
    );

    // ------------------------------------------------------------------------
    // On-Chip SRAM (256KB w/ SECDED ECC)
    // ------------------------------------------------------------------------
    sram_256k_ecc u_sram (
        .clk              (clk_soc),
        .rst_n            (rst_soc_n),
        .addr_i           (s0_awvalid ? s0_awaddr : s0_araddr),
        .wdata_i          (s0_wdata),
        .we_i             (s0_wvalid),
        .req_i            (s0_wvalid || s0_arvalid),
        .rdata_o          (s0_rdata),
        .ready_o          (s0_arready),
        .ecc_single_err_o (),
        .ecc_double_err_o (ecc_fault_nmi_o)
    );
    assign s0_awready = 1'b1;
    assign s0_wready  = 1'b1;
    assign s0_bvalid  = s0_wvalid;
    assign s0_rvalid  = s0_arvalid;

    // ------------------------------------------------------------------------
    // AI Accelerator CSRs & FSM Logic
    // ------------------------------------------------------------------------
    accel_csr_regs u_accel_csrs (
        .clk              (clk_soc),
        .rst_n            (rst_soc_n),
        .reg_addr_i       (s1_awaddr[5:0]),
        .reg_wdata_i      (s1_wdata[31:0]),
        .reg_write_i      (s1_wvalid),
        .reg_read_i       (s1_arvalid),
        .reg_rdata_o      (s1_rdata[31:0]),
        .accel_busy_i     (accel_busy),
        .accel_done_i     (accel_done),
        .accel_overflow_i (1'b0),
        .accel_bus_err_i  (1'b0),
        .start_pulse_o    (accel_start),
        .soft_reset_o     (accel_soft_reset),
        .int_en_o         (accel_int_en),
        .dma_en_o         (accel_dma_en),
        .mode_o           (accel_mode),
        .src_addr_o       (accel_src_addr),
        .dst_addr_o       (accel_dst_addr),
        .dim_m_o          (accel_dim_m),
        .dim_n_o          (accel_dim_n),
        .scale_o          (accel_scale),
        .shift_o          (accel_shift),
        .relu_en_o        (accel_relu_en),
        .intr_line_o      (accel_intr_line)
    );
    assign s1_rdata[63:32] = 32'b0;
    assign s1_awready = 1'b1;
    assign s1_wready  = 1'b1;
    assign s1_bvalid  = s1_wvalid;
    assign s1_arready = 1'b1;
    assign s1_rvalid  = s1_arvalid;

    accel_fsm_control u_accel_fsm (
        .clk           (clk_soc),
        .rst_n         (rst_soc_n),
        .start_i       (accel_start),
        .dma_rd_done_i (1'b1),
        .dma_wr_done_i (1'b1),
        .mac_done_i    (1'b1),
        .state_o       (accel_fsm_state),
        .accel_busy_o  (accel_busy),
        .accel_done_o  (accel_done)
    );

    // ------------------------------------------------------------------------
    // AXI-to-APB Bridge & CDC Async FIFO
    // ------------------------------------------------------------------------
    axi_to_apb_bridge u_axi_apb_bridge (
        .clk_soc       (clk_soc),
        .rst_soc_n     (rst_soc_n),
        .axi_awaddr_i  (s2_awaddr),  .axi_awvalid_i(s2_awvalid), .axi_awready_o(s2_awready),
        .axi_wdata_i   (s2_wdata[31:0]), .axi_wvalid_i (s2_wvalid),  .axi_wready_o (s2_wready),
        .axi_bresp_o   (s2_bresp),   .axi_bvalid_o (s2_bvalid),  .axi_bready_i (1'b1),
        .axi_araddr_i  (s2_araddr),  .axi_arvalid_i(s2_arvalid), .axi_arready_o(s2_arready),
        .axi_rdata_o   (s2_rdata[31:0]), .axi_rresp_o  (),           .axi_rvalid_o (s2_rvalid),
        .axi_rready_i  (1'b1),

        .clk_pclk      (clk_pclk),
        .rst_pclk_n    (rst_pclk_n),
        .apb_paddr_o   (apb_paddr),
        .apb_psel_o    (apb_psel),
        .apb_penable_o (apb_penable),
        .apb_pwrite_o  (apb_pwrite),
        .apb_pwdata_o  (apb_pwdata),
        .apb_prdata_i  (apb_prdata),
        .apb_pready_i  (apb_pready),
        .apb_pslverr_i (1'b0)
    );
    assign s2_rdata[63:32] = 32'b0;

    // ------------------------------------------------------------------------
    // Low-Speed Automotive Peripherals (APB Bus @ 50MHz)
    // ------------------------------------------------------------------------
    logic [31:0] can_prdata, uart_prdata;
    logic        can_pready, uart_pready;
    logic        sel_can, sel_uart;

    assign sel_can  = (apb_paddr[15:12] == 4'h1);
    assign sel_uart = (apb_paddr[15:12] == 4'h2);

    can_fd_controller u_can_fd (
        .clk_pclk   (clk_pclk),
        .rst_pclk_n (rst_pclk_n),
        .paddr_i    (apb_paddr),
        .psel_i     (apb_psel && sel_can),
        .penable_i  (apb_penable),
        .pwrite_i   (apb_pwrite),
        .pwdata_i   (apb_pwdata),
        .prdata_o   (can_prdata),
        .pready_o   (can_pready),
        .can_tx_o   (can_tx_o),
        .can_rx_i   (can_rx_i),
        .can_intr_o (can_intr)
    );

    uart_sensor_if u_uart (
        .clk_pclk   (clk_pclk),
        .rst_pclk_n (rst_pclk_n),
        .paddr_i    (apb_paddr),
        .psel_i     (apb_psel && sel_uart),
        .penable_i  (apb_penable),
        .pwrite_i   (apb_pwrite),
        .pwdata_i   (apb_pwdata),
        .prdata_o   (uart_prdata),
        .pready_o   (uart_pready),
        .uart_tx_o  (uart_tx_o),
        .uart_rx_i  (uart_rx_i),
        .uart_intr_o(uart_intr)
    );

    assign apb_prdata = sel_can ? can_prdata : sel_uart ? uart_prdata : 32'b0;
    assign apb_pready = sel_can ? can_pready : sel_uart ? uart_pready : 1'b1;

    assign soc_interrupt_o = accel_intr_line || can_intr || uart_intr;

endmodule
