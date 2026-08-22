param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("pe", "systolic", "npu_top")]
    [string]$tb
)

$root = Split-Path $PSScriptRoot -Parent
$simDir  = Join-Path $root "sim"
$rtlCore = Join-Path $root "rtl\core"
$vecDir  = Join-Path $root "sim\vectors"

New-Item -ItemType Directory -Force -Path $vecDir | Out-Null

switch ($tb) {
    "pe" {
        Write-Host "`n[SIM] Running PE testbench..." -ForegroundColor Cyan
        $out = Join-Path $vecDir "sim_pe.out"
        $f1 = Join-Path $rtlCore "pe.sv"
        $f2 = Join-Path $simDir  "tb_pe.sv"
        & iverilog -g2012 -o $out $f1 $f2
        if ($LASTEXITCODE -ne 0) { Write-Host "[ERROR] Compilation failed" -ForegroundColor Red; exit 1 }
        & vvp $out
    }
    "systolic" {
        Write-Host "`n[SIM] Running Systolic Array testbench..." -ForegroundColor Cyan
        $out = Join-Path $vecDir "sim_systolic.out"
        $f1 = Join-Path $rtlCore "pe.sv"
        $f2 = Join-Path $rtlCore "systolic_array.sv"
        $f3 = Join-Path $simDir  "tb_systolic_array.sv"
        & iverilog -g2012 -o $out $f1 $f2 $f3
        if ($LASTEXITCODE -ne 0) { Write-Host "[ERROR] Compilation failed" -ForegroundColor Red; exit 1 }
        & vvp $out
    }
    "npu_top" {
        Write-Host "`n[SIM] Running NPU Top testbench..." -ForegroundColor Cyan
        Write-Host "[INFO] npu_top not yet implemented (Month 2)" -ForegroundColor Yellow
    }
}

