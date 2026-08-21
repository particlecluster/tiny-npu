# NPU — Custom Neural Processing Unit on FPGA

A full-stack Neural Processing Unit built from scratch:
- **Hardware**: Parameterized systolic array in SystemVerilog (INT8 MAC grid)
- **Memory**: Double-buffered BRAM scratchpad + AXI4 DMA
- **ISA**: Custom NPU instruction set + sequencer controller
- **Compiler**: Python toolchain — ONNX to INT8 to NPU binary
- **Demo**: Real-time YOLOv5n on live camera feed (Kria KV260)
- **ASIC**: OpenLane + Sky130 tape-out via Google OpenMPW

## Architecture

```
PyTorch -> ONNX -> [NPU Compiler] -> .bin
                                    |
              FPGA: Sequencer -> Systolic Array (16x16 INT8 PEs)
                                    |
                           Weight BRAM / Act BRAM / DMA
```

## Repository Layout

```
npu/
├── rtl/
│   ├── core/           # pe.sv, systolic_array.sv, isa_decoder.sv, npu_sequencer.sv
│   ├── memory/         # weight_bram.sv, act_scratchpad.sv, dma_engine.sv
│   ├── peripherals/    # uart_ctrl.sv, hdmi_pipeline.sv
│   └── top/            # npu_arty7.sv, npu_kv260.sv
├── sim/
│   ├── golden/         # Python reference models
│   ├── vectors/        # Generated test vectors (auto, gitignored)
│   ├── tb_pe.sv
│   ├── tb_systolic_array.sv
│   └── tb_npu_top.sv
├── compiler/
│   ├── frontend/       # onnx_parser.py, graph_passes.py
│   ├── backend/        # quantizer.py, tiler.py, codegen.py, assembler.py
│   ├── runtime/        # host_loader.py
│   └── compile.py      # main entry point
├── models/
├── asic/               # OpenLane config for Sky130 tape-out
├── constraints/        # .xdc pin assignment files
└── scripts/
    ├── run_sim.ps1     # Simulation runner (Windows)
    └── synth.tcl       # Vivado synthesis script
```

## Quickstart

### 1. Install Icarus Verilog
Download the Windows installer from https://bleyer.org/icarus/
After installing, restart PowerShell.

### 2. Install Python deps
```powershell
pip install numpy onnx torch torchvision
```

### 3. Generate test vectors
```powershell
python sim/golden/gemm_ref.py
```

### 4. Run PE simulation
```powershell
.\scripts\run_sim.ps1 -tb pe
```

### 5. Run Systolic Array simulation
```powershell
.\scripts\run_sim.ps1 -tb systolic
```

### 6. View waveform
```powershell
# Install GTKWave: https://gtkwave.sourceforge.net/
gtkwave sim/vectors/wave_pe.vcd
```

## Build Milestones

| Week | Deliverable |
|------|-------------|
| 2    | Python golden model + test vectors |
| 5    | 8x8 systolic array passes all tests |
| 7    | Tiled GEMM on Arty A7 via UART |
| 9    | NPU executes hand-written conv ISA program |
| 12   | Auto-compile MobileNet to FPGA binary |
| 14   | Benchmark: TOPS, speedup vs CPU |
| 15   | Live YOLO demo on Kria KV260 |
| 16   | GDS layout to OpenMPW submission |

## References
- [Google TPU Paper](https://arxiv.org/abs/1704.04760)
- [MIT Eyeriss](https://people.csail.mit.edu/emer/papers/2016.06.isca.eyeriss_architecture.pdf)
- [Zero to ASIC Course](https://zerotoasiccourse.com/)
- [HDLBits SystemVerilog](https://hdlbits.01xz.net/)
