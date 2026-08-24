  // ============================================================================
// File: rtl/interconnect/axi_to_apb_bridge.sv
// Description: AXI4-Lite to APB3 Bridge Module with Integrated CDC Async FIFO
// Standard: SystemVerilog IEEE 1800-2017
// ============================================================================

module axi_to_apb_bridge (
    // High-Speed SoC Domain
    input  logic        clk_soc,
    input  logic        rst_soc_n,

    // AXI Slave Interface
    input  logic [31:0] axi_awaddr_i,
    input  logic        axi_awvalid_i,
    output logic        axi_awready_o,
    input  logic [31:0] axi_wdata_i,
    input  logic        axi_wvalid_i,
    output logic        axi_wready_o,
    output logic [1:0]  axi_bresp_o,
    output logic        axi_bvalid_o,
    input  logic        axi_bready_i,

    input  logic [31:0] axi_araddr_i,
    input  logic        axi_arvalid_i,
    output logic        axi_arready_o,
    output logic [31:0] axi_rdata_o,
    output logic [1:0]  axi_rresp_o,
    output logic        axi_rvalid_o,
    input  logic        axi_rready_i,

    // Low-Speed Peripheral Domain
    input  logic        clk_pclk,
    input  logic        rst_pclk_n,

    // APB Master Interface
    output logic [31:0] apb_paddr_o,
    output logic        apb_psel_o,
    output logic        apb_penable_o,
    output logic        apb_pwrite_o,
    output logic [31:0] apb_pwdata_o,
    input  logic [31:0] apb_prdata_i,
    input  logic        apb_pready_i,
    input  logic        apb_pslverr_i
);

    // CDC Async FIFO Signals
    logic [63:0] fifo_wdata, fifo_rdata;
    logic        fifo_winc, fifo_rinc;
    logic        fifo_wfull, fifo_rempty;

    assign fifo_wdata = {axi_wdata_i, axi_awaddr_i};
    assign fifo_winc  = (axi_awvalid_i && axi_wvalid_i && !fifo_wfull);

    assign axi_awready_o = !fifo_wfull;
    assign axi_wready_o  = !fifo_wfull;
    assign axi_bresp_o   = 2'b00; // OKAY
    assign axi_bvalid_o  = !fifo_rempty;

    assign axi_arready_o = 1'b1;
    assign axi_rdata_o   = apb_prdata_i;
    assign axi_rresp_o   = 2'b00;
    assign axi_rvalid_o  = apb_pready_i;

    cdc_async_fifo #(
        .D_WIDTH(64),
        .A_WIDTH(4)
    ) u_cdc_fifo (
        .wclk   (clk_soc),
        .wrst_n (rst_soc_n),
        .winc   (fifo_winc),
        .wdata  (fifo_wdata),
        .wfull  (fifo_wfull),
        .rclk   (clk_pclk),
        .rrst_n (rst_pclk_n),
        .rinc   (fifo_rinc),
        .rdata  (fifo_rdata),
        .rempty (fifo_rempty)
    );

    // APB FSM State Machine
    typedef enum logic [1:0] {
        APB_IDLE   = 2'b00,
        APB_SETUP  = 2'b01,
        APB_ENABLE = 2'b10
    } apb_state_e;

    apb_state_e apb_state_q, apb_state_d;

    always_ff @(posedge clk_pclk or negedge rst_pclk_n) begin
        if (!rst_pclk_n) apb_state_q <= APB_IDLE;
        else             apb_state_q <= apb_state_d;
    end

    always_comb begin
        apb_state_d   = apb_state_q;
        apb_psel_o    = 1'b0;
        apb_penable_o = 1'b0;
        apb_pwrite_o  = 1'b0;
        fifo_rinc     = 1'b0;

        case (apb_state_q)
            APB_IDLE: begin
                if (!fifo_rempty) begin
                    apb_state_d = APB_SETUP;
                end
            end
            APB_SETUP: begin
                apb_psel_o  = 1'b1;
                apb_pwrite_o= 1'b1;
                apb_state_d = APB_ENABLE;
            end
            APB_ENABLE: begin
                apb_psel_o    = 1'b1;
                apb_penable_o = 1'b1;
                apb_pwrite_o  = 1'b1;
                if (apb_pready_i) begin
                    fifo_rinc   = 1'b1;
                    apb_state_d = APB_IDLE;
                end
            end
            default: apb_state_d = APB_IDLE;
        endcase
    end

    assign apb_paddr_o  = fifo_rdata[31:0];
    assign apb_pwdata_o = fifo_rdata[63:32];

endmodule
