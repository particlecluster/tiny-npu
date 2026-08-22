// =============================================================================
// systolic_array.sv — NxN Weight-Stationary Systolic Array (TPU Architecture)
//
// 1. LOAD PHASE:
//    - Assert load_wgt = 1 for N cycles.
//    - Weights shift down each column: Row r receives B[r][c].
//
// 2. COMPUTE PHASE:
//    - Deassert load_wgt = 0.
//    - Activations A[i][k] stream in from the LEFT (skewed by row).
//    - Partial sums stream DOWN, starting from 0 at the top edge.
//    - Completed matrix product rows exit at psum_out at the BOTTOM.
//
// =============================================================================

`timescale 1ns/1ps

module systolic_array #(
    parameter int N          = 8,   // NxN grid
    parameter int DATA_WIDTH = 8,
    parameter int ACC_WIDTH  = 32
)(
    input  logic                           clk,
    input  logic                           rst_n,
    input  logic                           load_wgt,

    // Top inputs: weights during load, top psum during compute (normally 0)
    input  logic signed [DATA_WIDTH-1:0]   wgt_in   [N],
    input  logic signed [ACC_WIDTH-1:0]    psum_top [N],

    // Left inputs: activations stream left -> right
    input  logic signed [DATA_WIDTH-1:0]   act_in   [N],

    // Bottom outputs: final accumulated results
    output logic signed [ACC_WIDTH-1:0]    psum_out [N]
);

    // 2D Interconnect mesh
    logic signed [DATA_WIDTH-1:0] act_h  [N][N+1];
    logic signed [DATA_WIDTH-1:0] wgt_v  [N+1][N];
    logic signed [ACC_WIDTH-1:0]  psum_v [N+1][N];

    // Boundary assignments
    for (genvar r = 0; r < N; r++) begin
        assign act_h[r][0] = act_in[r];
    end
    for (genvar c = 0; c < N; c++) begin
        assign wgt_v[0][c]  = wgt_in[c];
        assign psum_v[0][c] = psum_top[c];
        assign psum_out[c]  = psum_v[N][c];
    end

    // Instantiate PE grid
    for (genvar r = 0; r < N; r++) begin : row
        for (genvar c = 0; c < N; c++) begin : col
            pe #(
                .DATA_WIDTH (DATA_WIDTH),
                .ACC_WIDTH  (ACC_WIDTH)
            ) u_pe (
                .clk      (clk),
                .rst_n    (rst_n),
                .load_wgt (load_wgt),
                .act_in   (act_h[r][c]),
                .act_out  (act_h[r][c+1]),
                .wgt_in   (wgt_v[r][c]),
                .wgt_out  (wgt_v[r+1][c]),
                .psum_in  (psum_v[r][c]),
                .psum_out (psum_v[r+1][c])
            );
        end
    end

endmodule
