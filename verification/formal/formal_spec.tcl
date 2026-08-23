# Cadence JasperGold Formal Verification Script

analyze -sv rtl/interconnect/axi4_crossbar.sv
analyze -sv rtl/interconnect/cdc_async_fifo.sv
analyze -sv rtl/accelerator/accel_fsm_control.sv
analyze -sv verification/formal/accel_formal_props.sv

elaborate -top accel_formal_props

clock clk
reset -expression (!rst_n)

prove -all
report_proof -all -out verification/formal/formal_results/proof_summary.rpt
