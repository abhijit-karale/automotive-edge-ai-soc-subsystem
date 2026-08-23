// ============================================================================
// File: rtl/interconnect/cdc_async_fifo.sv
// Description: Dual-Clock Asynchronous CDC FIFO with 2FF Gray Pointer Synchronization
// Standard: SystemVerilog IEEE 1800-2017
// ============================================================================

module cdc_async_fifo #(
    parameter int D_WIDTH = 32,
    parameter int A_WIDTH = 4
)(
    // Write Domain (High-Speed SoC Clock)
    input  logic               wclk,
    input  logic               wrst_n,
    input  logic               winc,
    input  logic [D_WIDTH-1:0] wdata,
    output logic               wfull,

    // Read Domain (Low-Speed Peripheral Clock)
    input  logic               rclk,
    input  logic               rrst_n,
    input  logic               rinc,
    output logic [D_WIDTH-1:0] rdata,
    output logic               rempty
);
    localparam int DEPTH = 1 << A_WIDTH;

    logic [D_WIDTH-1:0] mem [0:DEPTH-1];
    logic [A_WIDTH:0]   wptr_bin, wptr_gray, rptr_bin, rptr_gray;
    logic [A_WIDTH:0]   wq2_rptr, rq2_wptr;
    logic [A_WIDTH:0]   rptr_gray_sync1, wptr_gray_sync1;

    // Memory Write
    always_ff @(posedge wclk) begin
        if (winc && !wfull) mem[wptr_bin[A_WIDTH-1:0]] <= wdata;
    end
    assign rdata = mem[rptr_bin[A_WIDTH-1:0]];

    // Binary to Gray conversion helper
    function automatic logic [A_WIDTH:0] bin2gray(input logic [A_WIDTH:0] bin);
        return bin ^ (bin >> 1);
    endfunction

    // Write Pointer Logic
    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr_bin  <= '0;
            wptr_gray <= '0;
        end else if (winc && !wfull) begin
            wptr_bin  <= wptr_bin + 1'b1;
            wptr_gray <= bin2gray(wptr_bin + 1'b1);
        end
    end

    // Read Pointer Logic
    always_ff @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr_bin  <= '0;
            rptr_gray <= '0;
        end else if (rinc && !rempty) begin
            rptr_bin  <= rptr_bin + 1'b1;
            rptr_gray <= bin2gray(rptr_bin + 1'b1);
        end
    end

    // 2-Stage Flip-Flop Synchronizers
    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) {wq2_rptr, rptr_gray_sync1} <= '0;
        else        {wq2_rptr, rptr_gray_sync1} <= {rptr_gray_sync1, rptr_gray};
    end

    always_ff @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) {rq2_wptr, wptr_gray_sync1} <= '0;
        else        {rq2_wptr, wptr_gray_sync1} <= {wptr_gray_sync1, wptr_gray};
    end

    // Empty and Full Flag Generation
    assign rempty = (rptr_gray == rq2_wptr);
    assign wfull  = (wptr_gray == {~wq2_rptr[A_WIDTH:A_WIDTH-1], wq2_rptr[A_WIDTH-2:0]});

endmodule
