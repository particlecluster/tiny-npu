"""
compile.py — NPU Compiler Entry Point

Usage:
    python compiler/compile.py <model.onnx> [--output npu.bin] [--tile-size 8]

This is the skeleton/entry point. The full compiler is built in Month 3.
For now, it documents the compilation pipeline and stubs out each stage.

Pipeline:
    ONNX model
        -> parse graph (frontend/onnx_parser.py)
        -> fuse layers (frontend/graph_passes.py)
        -> quantize to INT8 (backend/quantizer.py)
        -> tile for BRAM (backend/tiler.py)
        -> generate ISA (backend/codegen.py)
        -> assemble binary (backend/assembler.py)
        -> .bin file
"""

import argparse
import sys
import os

sys.path.insert(0, os.path.dirname(__file__))


def main():
    parser = argparse.ArgumentParser(description="NPU Compiler: ONNX -> NPU binary")
    parser.add_argument("model", help="Path to input .onnx model")
    parser.add_argument("--output", default="npu.bin", help="Output binary path")
    parser.add_argument("--tile-size", type=int, default=8,
                        help="Systolic array tile size (default: 8)")
    parser.add_argument("--verbose", action="store_true", help="Print detailed IR")
    args = parser.parse_args()

    print(f"\nNPU Compiler")
    print(f"  Input:     {args.model}")
    print(f"  Output:    {args.output}")
    print(f"  Tile size: {args.tile_size}x{args.tile_size}")
    print()

    # ---- Stage 1: Parse ONNX ----
    print("[1/6] Parsing ONNX graph...")
    # from frontend.onnx_parser import load_model
    # layers = load_model(args.model)
    print("      TODO: implement in Month 3 (frontend/onnx_parser.py)")

    # ---- Stage 2: Graph optimization ----
    print("[2/6] Fusing layers (Conv+BN+ReLU)...")
    # from frontend.graph_passes import fuse_conv_bn_relu
    # layers = fuse_conv_bn_relu(layers)
    print("      TODO: implement in Month 3 (frontend/graph_passes.py)")

    # ---- Stage 3: INT8 Quantization ----
    print("[3/6] Quantizing to INT8...")
    # from backend.quantizer import quantize_model
    # q_layers = quantize_model(layers)
    print("      TODO: implement in Month 3 (backend/quantizer.py)")

    # ---- Stage 4: Tiling ----
    print("[4/6] Tiling for BRAM...")
    # from backend.tiler import tile_model
    # tiled = tile_model(q_layers, tile_size=args.tile_size)
    print("      TODO: implement in Month 3 (backend/tiler.py)")

    # ---- Stage 5: Code generation ----
    print("[5/6] Generating NPU ISA...")
    # from backend.codegen import generate
    # asm = generate(tiled)
    print("      TODO: implement in Month 3 (backend/codegen.py)")

    # ---- Stage 6: Assemble ----
    print("[6/6] Assembling binary...")
    # from backend.assembler import assemble
    # binary = assemble(asm)
    # with open(args.output, 'wb') as f:
    #     f.write(binary)
    print("      TODO: implement in Month 3 (backend/assembler.py)")

    print(f"\n  Compiler stub complete. Build Month 3 to make this real.\n")


if __name__ == "__main__":
    main()