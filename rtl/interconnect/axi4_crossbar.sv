// ============================================================================
// File: rtl/interconnect/axi4_crossbar.sv
// Description: 64-bit 2-Master to 3-Slave AXI4 Crossbar Interconnect with Round-Robin Arbiter
// Standard: SystemVerilog IEEE 1800-2017
// ============================================================================

module axi4_crossbar (
    input  logic        clk,
    input  logic        rst_n,

    // Master 0 Interface (RV32I Core)
    input  logic [31:0] m0_awaddr,  input  logic m0_awvalid, output logic m0_awready,
    input  logic [64:0] m0_wdata,   input  logic m0_wvalid,  output logic m0_wready,
    output logic [1:0]  m0_bresp,   output logic m0_bvalid,  input  logic m0_bready,
    input  logic [31:0] m0_araddr,  input  logic m0_arvalid, output logic m0_arready,
    output logic [63:0] m0_rdata,   output logic m0_rvalid,  input  logic m0_rready,

    // Master 1 Interface (Scatter-Gather DMA)
    input  logic [31:0] m1_awaddr,  input  logic m1_awvalid, output logic m1_awready,
    input  logic [63:0] m1_wdata,   input  logic m1_wvalid,  output logic m1_wready,
    output logic [1:0]  m1_bresp,   output logic m1_bvalid,  input  logic m1_bready,
    input  logic [31:0] m1_araddr,  input  logic m1_arvalid, output logic m1_arready,
    output logic [63:0] m1_rdata,   output logic m1_rvalid,  input  logic m1_rready,

    // Slave 0 Interface (SRAM Memory Subsystem: 0x2000_0000)
    output logic [31:0] s0_awaddr,  output logic s0_awvalid, input  logic s0_awready,
    output logic [63:0] s0_wdata,   output logic s0_wvalid,  input  logic s0_wready,
    input  logic [1:0]  s0_bresp,   input  logic s0_bvalid,  output logic s0_bready,
    output logic [31:0] s0_araddr,  output logic s0_arvalid, input  logic s0_arready,
    input  logic [63:0] s0_rdata,   input  logic s0_rvalid,  output logic s0_rready,

    // Slave 1 Interface (AI Accelerator CSRs: 0x4000_0000)
    output logic [31:0] s1_awaddr,  output logic s1_awvalid, input  logic s1_awready,
    output logic [63:0] s1_wdata,   output logic s1_wvalid,  input  logic s1_wready,
    input  logic [1:0]  s1_bresp,   input  logic s1_bvalid,  output logic s1_bready,
    output logic [31:0] s1_araddr,  output logic s1_arvalid, input  logic s1_arready,
    input  logic [63:0] s1_rdata,   input  logic s1_rvalid,  output logic s1_rready,

    // Slave 2 Interface (AXI-to-APB Bridge: 0x5000_0000)
    output logic [31:0] s2_awaddr,  output logic s2_awvalid, input  logic s2_awready,
    output logic [63:0] s2_wdata,   output logic s2_wvalid,  input  logic s2_wready,
    input  logic [1:0]  s2_bresp,   input  logic s2_bvalid,  output logic s2_bready,
    output logic [31:0] s2_araddr,  output logic s2_arvalid, input  logic s2_arready,
    input  logic [63:0] s2_rdata,   input  logic s2_rvalid,  output logic s2_rready
);

    // Round-Robin Arbiter State
    logic arb_gnt; // 0: Master 0, 1: Master 1

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            arb_gnt <= 1'b0;
        end else begin
            if (m0_arvalid || m0_awvalid) arb_gnt <= 1'b0;
            else if (m1_arvalid || m1_awvalid) arb_gnt <= 1'b1;
        end
    end

    // Selected Master Address Routing
    logic [31:0] sel_awaddr, sel_araddr;
    logic [63:0] sel_wdata;
    logic        sel_awvalid, sel_wvalid, sel_arvalid;

    assign sel_awaddr  = (arb_gnt) ? m1_awaddr  : m0_awaddr;
    assign sel_awvalid = (arb_gnt) ? m1_awvalid : m0_awvalid;
    assign sel_wdata   = (arb_gnt) ? m1_wdata   : m0_wdata[63:0];
    assign sel_wvalid  = (arb_gnt) ? m1_wvalid  : m0_wvalid;

    assign sel_araddr  = (arb_gnt) ? m1_araddr  : m0_araddr;
    assign sel_arvalid = (arb_gnt) ? m1_arvalid : m0_arvalid;

    // Address Decoding (0x2000 -> S0, 0x4000 -> S1, 0x5000 -> S2)
    logic sel_s0_w, sel_s1_w, sel_s2_w;
    logic sel_s0_r, sel_s1_r, sel_s2_r;

    assign sel_s0_w = (sel_awaddr[31:24] == 8'h20);
    assign sel_s1_w = (sel_awaddr[31:24] == 8'h40);
    assign sel_s2_w = (sel_awaddr[31:24] == 8'h50);

    assign sel_s0_r = (sel_araddr[31:24] == 8'h20);
    assign sel_s1_r = (sel_araddr[31:24] == 8'h40);
    assign sel_s2_r = (sel_araddr[31:24] == 8'h50);

    // Route to Slave 0 (SRAM)
    assign s0_awaddr  = sel_awaddr;
    assign s0_awvalid = sel_awvalid && sel_s0_w;
    assign s0_wdata   = sel_wdata;
    assign s0_wvalid  = sel_wvalid && sel_s0_w;
    assign s0_araddr  = sel_araddr;
    assign s0_arvalid = sel_arvalid && sel_s0_r;
    assign s0_bready  = 1'b1;
    assign s0_rready  = 1'b1;

    // Route to Slave 1 (AI Accelerator)
    assign s1_awaddr  = sel_awaddr;
    assign s1_awvalid = sel_awvalid && sel_s1_w;
    assign s1_wdata   = sel_wdata;
    assign s1_wvalid  = sel_wvalid && sel_s1_w;
    assign s1_araddr  = sel_araddr;
    assign s1_arvalid = sel_arvalid && sel_s1_r;
    assign s1_bready  = 1'b1;
    assign s1_rready  = 1'b1;

    // Route to Slave 2 (APB Bridge)
    assign s2_awaddr  = sel_awaddr;
    assign s2_awvalid = sel_awvalid && sel_s2_w;
    assign s2_wdata   = sel_wdata;
    assign s2_wvalid  = sel_wvalid && sel_s2_w;
    assign s2_araddr  = sel_araddr;
    assign s2_arvalid = sel_arvalid && sel_s2_r;
    assign s2_bready  = 1'b1;
    assign s2_rready  = 1'b1;

    // Master Response Routing
    assign m0_awready = (!arb_gnt) && ((sel_s0_w && s0_awready) || (sel_s1_w && s1_awready) || (sel_s2_w && s2_awready));
    assign m0_wready  = (!arb_gnt) && ((sel_s0_w && s0_wready)  || (sel_s1_w && s1_wready)  || (sel_s2_w && s2_wready));
    assign m0_arready = (!arb_gnt) && ((sel_s0_r && s0_arready) || (sel_s1_r && s1_arready) || (sel_s2_r && s2_arready));

    assign m0_rdata  = sel_s0_r ? s0_rdata : sel_s1_r ? s1_rdata : s2_rdata;
    assign m0_rvalid = sel_s0_r ? s0_rvalid : sel_s1_r ? s1_rvalid : s2_rvalid;
    assign m0_bresp  = 2'b00; // OKAY
    assign m0_bvalid = sel_s0_w ? s0_bvalid : sel_s1_w ? s1_bvalid : s2_bvalid;

    assign m1_awready = arb_gnt && ((sel_s0_w && s0_awready) || (sel_s1_w && s1_awready) || (sel_s2_w && s2_awready));
    assign m1_wready  = arb_gnt && ((sel_s0_w && s0_wready)  || (sel_s1_w && s1_wready)  || (sel_s2_w && s2_wready));
    assign m1_arready = arb_gnt && ((sel_s0_r && s0_arready) || (sel_s1_r && s1_arready) || (sel_s2_r && s2_arready));

    assign m1_rdata  = sel_s0_r ? s0_rdata : sel_s1_r ? s1_rdata : s2_rdata;
    assign m1_rvalid = sel_s0_r ? s0_rvalid : sel_s1_r ? s1_rvalid : s2_rvalid;
    assign m1_bresp  = 2'b00; // OKAY
    assign m1_bvalid = sel_s0_w ? s0_bvalid : sel_s1_w ? s1_bvalid : s2_bvalid;

endmodule
