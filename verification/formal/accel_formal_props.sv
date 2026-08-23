// ============================================================================
// File: verification/formal/accel_formal_props.sv
// Description: SystemVerilog Assertions (SVA) Package for Cadence JasperGold
// Standard: SystemVerilog IEEE 1800-2017
// ============================================================================

module accel_formal_props #(
    parameter int MAX_LATENCY = 16
)(
    input logic clk,
    input logic rst_n,

    // AXI Bus Signals
    input logic awvalid, input logic awready,
    input logic wvalid,  input logic wready,
    input logic bvalid,  input logic bready,
    input logic [1:0] req_vec, input logic [1:0] gnt_vec,

    // CDC FIFO Signals
    input logic winc, input logic wfull,
    input logic [4:0] wptr_gray,

    // Interrupt Signals
    input logic intr_line,
    input logic intr_clear_w1c,

    // FSM State Signals
    input logic [2:0] fsm_state
);

    default clocking cb_soc @(posedge clk); endclocking
    default disable iff (!rst_n);

    // ------------------------------------------------------------------------
    // Property 1: AXI4 Arbiter Fairness (No Master Starvation)
    // ------------------------------------------------------------------------
    property p_arbiter_fairness;
        req_vec[0] |-> ##[1:MAX_LATENCY] gnt_vec[0];
    endproperty
    assert_arbiter_fairness: assert property (p_arbiter_fairness)
        else $error("[FORMAL ERROR] Master 0 Starved by Arbiter!");

    // ------------------------------------------------------------------------
    // Property 2: AXI Handshake Stability & Deadlock Freedom
    // ------------------------------------------------------------------------
    property p_axi_awvalid_stability;
        awvalid && !awready |=> awvalid && $stable(awvalid);
    endproperty
    assert_axi_awvalid_stability: assert property (p_axi_awvalid_stability)
        else $error("[FORMAL ERROR] AWVALID dropped before AWREADY!");

    // ------------------------------------------------------------------------
    // Property 3: CDC Async FIFO Single-Bit Gray Code Property
    // ------------------------------------------------------------------------
    property p_cdc_gray_single_bit;
        winc && !wfull |=> $countones(wptr_gray ^ $past(wptr_gray)) <= 1;
    endproperty
    assert_cdc_gray_single_bit: assert property (p_cdc_gray_single_bit)
        else $error("[FORMAL ERROR] CDC Gray pointer multi-bit flip detected!");

    // ------------------------------------------------------------------------
    // Property 4: Interrupt Persistence until W1C Acknowledged
    // ------------------------------------------------------------------------
    property p_interrupt_persistence;
        intr_line && !intr_clear_w1c |=> intr_line;
    endproperty
    assert_interrupt_persist: assert property (p_interrupt_persistence)
        else $error("[FORMAL ERROR] Interrupt deasserted without W1C clear!");

    // ------------------------------------------------------------------------
    // Property 5: FSM State Safety & Unreachable State Absence
    // ------------------------------------------------------------------------
    property p_fsm_valid_state;
        fsm_state inside {3'b000, 3'b001, 3'b010, 3'b011, 3'b100, 3'b101};
    endproperty
    assert_fsm_valid: assert property (p_fsm_valid_state)
        else $error("[FORMAL ERROR] FSM entered illegal state!");

endmodule
