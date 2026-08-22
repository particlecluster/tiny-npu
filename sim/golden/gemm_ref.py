"""
gemm_ref.py — 8x8 Weight-Stationary Golden Reference Model & Vector Generator
Generates randomized INT8 test matrices and exact INT32 golden reference outputs.
Exports hex vector files for SystemVerilog testbenches.
"""

import numpy as np
import os

N = 8
DATA_WIDTH = 8
ACC_WIDTH = 32

VECTORS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "vectors"))
os.makedirs(VECTORS_DIR, exist_ok=True)

def export_hex_8bit(matrix: np.ndarray, filepath: str):
    """Exports NxN INT8 matrix as 2-digit hex values."""
    with open(filepath, "w") as f:
        for row in matrix:
            line = " ".join(f"{(int(val) & 0xFF):02X}" for val in row)
            f.write(line + "\n")

def export_hex_32bit(matrix: np.ndarray, filepath: str):
    """Exports NxN INT32 matrix as 8-digit hex values."""
    with open(filepath, "w") as f:
        for row in matrix:
            line = " ".join(f"{(int(val) & 0xFFFFFFFF):08X}" for val in row)
            f.write(line + "\n")

def print_matrix(name: str, mat: np.ndarray):
    print(f"\n--- {name} ({mat.shape[0]}x{mat.shape[1]}, {mat.dtype}) ---")
    rows, cols = mat.shape
    col_width = max(len(str(val)) for val in mat.flatten()) + 2
    for r in range(rows):
        row_str = " ".join(f"{mat[r, c]:>{col_width}}" for c in range(cols))
        print(f"  [{row_str} ]")

def generate_vectors(seed: int = 42, low: int = -30, high: int = 30):
    np.random.seed(seed)

    # Generate randomized INT8 matrices within a representative numerical range
    A = np.random.randint(low, high + 1, size=(N, N), dtype=np.int8)
    B = np.random.randint(low, high + 1, size=(N, N), dtype=np.int8)

    # Compute INT32 Golden Matrix Product C = A x B
    C = A.astype(np.int32) @ B.astype(np.int32)

    # Paths
    a_path = os.path.join(VECTORS_DIR, "A_8x8.hex")
    b_path = os.path.join(VECTORS_DIR, "B_8x8.hex")
    c_path = os.path.join(VECTORS_DIR, "C_ref_8x8.hex")

    export_hex_8bit(A, a_path)
    export_hex_8bit(B, b_path)
    export_hex_32bit(C, c_path)

    print("================================================================================")
    print(f" 8x8 Weight-Stationary Systolic Array Golden Model (Seed = {seed})")
    print("================================================================================")
    print_matrix("Matrix A (Activations - INT8)", A)
    print_matrix("Matrix B (Weights - INT8)", B)
    print_matrix("Golden Reference Matrix C = A x B (INT32)", C)

    print("\n------------------------------ Summary Statistics ------------------------------")
    print(f"  Matrix A stats   : min={A.min():>4}, max={A.max():>4}, mean={A.mean():>6.2f}, nonzero={np.count_nonzero(A)}/64")
    print(f"  Matrix B stats   : min={B.min():>4}, max={B.max():>4}, mean={B.mean():>6.2f}, nonzero={np.count_nonzero(B)}/64")
    print(f"  Matrix C stats   : min={C.min():>4}, max={C.max():>4}, mean={C.mean():>6.2f}, nonzero={np.count_nonzero(C)}/64")

    print("\n---------------------------- Spot Check Validations ----------------------------")
    print(f"  C[0, 0] = sum(A[0, :] * B[:, 0]) = {C[0, 0]}")
    print(f"  C[0, 7] = sum(A[0, :] * B[:, 7]) = {C[0, 7]}")
    print(f"  C[7, 0] = sum(A[7, :] * B[:, 0]) = {C[7, 0]}")
    print(f"  C[7, 7] = sum(A[7, :] * B[:, 7]) = {C[7, 7]}")

    print("\n------------------------------ Exported Hex Files ------------------------------")
    print(f"  [+] Activations : {a_path}")
    print(f"  [+] Weights     : {b_path}")
    print(f"  [+] Reference C : {c_path}")
    print("================================================================================\n")

    return A, B, C

if __name__ == "__main__":
    generate_vectors()