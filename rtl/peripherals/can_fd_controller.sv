// ============================================================================
// File: rtl/peripherals/can_fd_controller.sv
// Description: CAN-FD Controller Stub with APB Interface & Message Buffers
// Standard: SystemVerilog IEEE 1800-2017
// ============================================================================

module can_fd_controller (
    input  logic        clk_pclk,
    input  logic        rst_pclk_n,

    // APB Slave Interface
    input  logic [31:0] paddr_i,
    input  logic        psel_i,
    input  logic        penable_i,
    input  logic        pwrite_i,
    input  logic [31:0] pwdata_i,
    output logic [31:0] prdata_o,
    output logic        pready_o,

    // Physical CAN Bus Pins
    output logic        can_tx_o,
    input  logic        can_rx_i,

    // Interrupt Line
    output logic        can_intr_o
);

    logic [31:0] tx_fifo_q;
    logic [31:0] rx_fifo_q;
    logic        tx_busy_q;

    assign pready_o = 1'b1;

    always_ff @(posedge clk_pclk or negedge rst_pclk_n) begin
        if (!rst_pclk_n) begin
            tx_fifo_q  <= 32'b0;
            rx_fifo_q  <= 32'hCAFE_BABE;
            tx_busy_q  <= 1'b0;
            can_tx_o   <= 1'b1; // Idle high
            can_intr_o <= 1'b0;
        end else begin
            can_intr_o <= 1'b0;
            if (psel_i && penable_i && pwrite_i) begin
                if (paddr_i[5:0] == 6'h10) begin // CAN_TX_FIFO
                    tx_fifo_q  <= pwdata_i;
                    tx_busy_q  <= 1'b1;
                    can_tx_o   <= 1'b0; // Start bit
                    can_intr_o <= 1'b1; // TX done interrupt
                end
            end
        end
    end

    always_comb begin
        if (psel_i && !pwrite_i) begin
            case (paddr_i[5:0])
                6'h00: prdata_o = {31'b0, tx_busy_q};
                6'h10: prdata_o = tx_fifo_q;
                6'h14: prdata_o = rx_fifo_q;
                default: prdata_o = 32'b0;
            endcase
        end else begin
            prdata_o = 32'b0;
        end
    end

endmodule
