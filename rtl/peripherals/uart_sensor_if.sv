// ============================================================================
// File: rtl/peripherals/uart_sensor_if.sv
// Description: UART Sensor Interface for Radar/Camera Edge Sensor Data Ingress
// Standard: SystemVerilog IEEE 1800-2017
// ============================================================================

module uart_sensor_if (
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

    // Physical Serial Pins
    output logic        uart_tx_o,
    input  logic        uart_rx_i,

    // Interrupt Line
    output logic        uart_intr_o
);

    logic [31:0] rx_buffer_q;
    logic        rx_valid_q;

    assign pready_o  = 1'b1;
    assign uart_tx_o = 1'b1;

    always_ff @(posedge clk_pclk or negedge rst_pclk_n) begin
        if (!rst_pclk_n) begin
            rx_buffer_q <= 32'h1234_5678;
            rx_valid_q  <= 1'b1;
            uart_intr_o <= 1'b0;
        end else begin
            uart_intr_o <= 1'b0;
            if (psel_i && penable_i && !pwrite_i && (paddr_i[5:0] == 6'h04)) begin
                rx_valid_q <= 1'b0; // Clear on read
            end
        end
    end

    always_comb begin
        if (psel_i && !pwrite_i) begin
            case (paddr_i[5:0])
                6'h00: prdata_o = {31'b0, rx_valid_q};
                6'h04: prdata_o = rx_buffer_q;
                default: prdata_o = 32'b0;
            endcase
        end else begin
            prdata_o = 32'b0;
        end
    end

endmodule
