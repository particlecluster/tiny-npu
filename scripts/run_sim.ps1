# =============================================================================
# run_sim.ps1 — Simulation runner for the NPU project (Windows/PowerShell)
#
# USAGE:
#   .\scripts\run_sim.ps1 -tb pe          # run PE testbench
#   .\scripts\run_sim.ps1 -tb systolic    # run systolic array testbench
#   .\scripts\run_sim.ps1 -tb npu_top     # run full NPU testbench
#
# REQUIRES: iverilog (Icarus Verilog) installed
#   Download: https://bleyer.org/icarus/  (iverilog-v12-20220611-x64_setup.exe)
#   After installing, restart PowerShell so iverilog is in PATH.
#
# =============================================================================

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("pe", "systolic", "npu_top")]
    [string]$tb
)

$root = Split-Path $PSScriptRoot -Parent
$simDir  = Join-Path $root "sim"
$rtlCore = Join-Path $root "rtl\core"
$vecDir  = Join-Path $root "sim\vectors"

# Create vectors dir if it doesn't exist
New-Item -ItemType Directory -Force -Path $vecDir | Out-Null

switch ($tb) {
    "pe" {
        Write-Host "`n[SIM] Running PE testbench..." -ForegroundColor Cyan
        $sources = @(
            Join-Path $rtlCore "pe.sv",
            Join-Path $simDir  "tb_pe.sv"
        )
        $out = Join-Path $vecDir "sim_pe.out"
        iverilog -g2012 -o $out @sources
        if ($LASTEXITCODE -ne 0) { Write-Host "[ERROR] Compilation failed" -ForegroundColor Red; exit 1 }
        vvp $out
    }
    "systolic" {
        Write-Host "`n[SIM] Running Systolic Array testbench..." -ForegroundColor Cyan
        $sources = @(
            Join-Path $rtlCore "pe.sv",
            Join-Path $rtlCore "systolic_array.sv",
            Join-Path $simDir  "tb_systolic_array.sv"
        )
        $out = Join-Path $vecDir "sim_systolic.out"
        iverilog -g2012 -o $out @sources
        if ($LASTEXITCODE -ne 0) { Write-Host "[ERROR] Compilation failed" -ForegroundColor Red; exit 1 }
        vvp $out
    }
    "npu_top" {
        Write-Host "`n[SIM] Running NPU Top testbench..." -ForegroundColor Cyan
        Write-Host "[INFO] npu_top not yet implemented (Month 2)" -ForegroundColor Yellow
    }
}

Write-Host "`n[INFO] Waveform saved to sim/vectors/wave_$tb.vcd" -ForegroundColor Green
Write-Host "[INFO] Open with GTKWave: gtkwave sim/vectors/wave_$tb.vcd`n" -ForegroundColor Green
