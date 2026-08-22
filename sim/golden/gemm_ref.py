"""
gemm_ref.py — Weight-Stationary Golden Reference Model
"""

import numpy as np
import os

N = 2
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "vectors")
os.makedirs(OUTPUT_DIR, exist_ok=True)

def run_golden():
    # 2x2 Test Case
    A = np.array([[1, 2], [3, 4]], dtype=np.int8)
    B = np.array([[5, 6], [7, 8]], dtype=np.int8)
    C = A.astype(np.int32) @ B.astype(np.int32)

    print("========================================")
    print(" Weight-Stationary Reference GEMM")
    print("========================================")
    print("\nMatrix A (Activations):\n", A)
    print("\nMatrix B (Weights):\n", B)
    print("\nGolden Matrix C = A x B:\n", C)
    print(f"\nc00 = {C[0,0]} (expected 1*5 + 2*7 = 19)")
    print(f"c01 = {C[0,1]} (expected 1*6 + 2*8 = 22)")
    print(f"c10 = {C[1,0]} (expected 3*5 + 4*7 = 43)")
    print(f"c11 = {C[1,1]} (expected 3*6 + 4*8 = 50)")

if __name__ == "__main__":
    run_golden()