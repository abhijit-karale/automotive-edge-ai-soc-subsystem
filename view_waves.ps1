# ============================================================================
# Script: view_waves.ps1
# Description: Launch QuestaSim GUI with Waveform Viewer
# ============================================================================

$env:PATH += ";C:\questasim64_10.7c\win64"

Write-Host "Opening QuestaSim Waveform Viewer..." -ForegroundColor Green
vsim -gui work.tb_soc_top -do "add wave -r /*; run -all"
