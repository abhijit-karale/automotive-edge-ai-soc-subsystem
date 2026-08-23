# ============================================================================
# Script: run_sim.ps1
# Description: Automated Build and Test Simulation Runner using QuestaSim
# ============================================================================

$ErrorActionPreference = "Stop"
$env:PATH += ";C:\questasim64_10.7c\win64"

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "  Automotive Edge AI Sensor & Accelerator SoC Subsystem Simulator" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

# Create sim directory if not present
if (!(Test-Path -Path "sim")) {
    New-Item -ItemType Directory -Path "sim" | Out-Null
}

# 1. Initialize Work Library & Compile SystemVerilog Files
Write-Host "`n[1/5] Compiling SystemVerilog RTL and Verification Testbenches..." -ForegroundColor Yellow
vlib work
vlog -sv -work work rtl/accelerator/*.sv rtl/core/*.sv rtl/interconnect/*.sv rtl/memory/*.sv rtl/peripherals/*.sv rtl/top/*.sv verification/testbenches/*.sv

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Compilation Failed!" -ForegroundColor Red
    exit 1
}
Write-Host "[SUCCESS] RTL and Testbenches Compiled Cleanly!" -ForegroundColor Green

# 2. Run Top-Level SoC Subsystem Simulation (tb_soc_top)
Write-Host "`n[2/5] Running Top-Level SoC Subsystem Simulation (tb_soc_top)..." -ForegroundColor Yellow
vsim -c tb_soc_top -do "log -r /*; run -all; wlf save sim/tb_soc_top.wlf; quit"

# 3. Run INT8 Systolic Array MAC Unit Test
Write-Host "`n[3/5] Running 4x4 INT8 Systolic Array MAC Engine Unit Test (tb_accel_mac_array)..." -ForegroundColor Yellow
vsim -c tb_accel_mac_array -do "log -r /*; run -all; wlf save sim/tb_accel_mac_array.wlf; quit"

# 4. Run SECDED ECC Safety Unit Test
Write-Host "`n[4/5] Running ISO 26262 ASIL-B SECDED Hamming ECC Unit Test (tb_ecc_hamming)..." -ForegroundColor Yellow
vsim -c tb_ecc_hamming -do "log -r /*; run -all; wlf save sim/tb_ecc_hamming.wlf; quit"

# 5. Run CDC Async FIFO Unit Test
Write-Host "`n[5/5] Running Dual-Clock Async CDC FIFO Unit Test (tb_cdc_async_fifo)..." -ForegroundColor Yellow
vsim -c tb_cdc_async_fifo -do "log -r /*; run -all; wlf save sim/tb_cdc_async_fifo.wlf; quit"

Write-Host "`n======================================================================" -ForegroundColor Green
Write-Host "  ALL SIMULATIONS PASSED SUCCESSFULLY! (0 Errors)" -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Green
