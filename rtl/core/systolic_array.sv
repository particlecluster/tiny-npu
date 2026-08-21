// =============================================================================
// systolic_array.sv — NxN grid of Processing Elements
//
// HOW IT WORKS:
//   This wires N×N PE instances together into a 2D mesh.
//   It's a 2D pipeline — think of each row as a pipeline,
//   and each column as another pipeline running simultaneously.
//
//   COMPUTING C = A × B  (where A is M×K, B is K×N):
//     - Weights (from B) enter from the TOP, one column per column of PEs
//     - Activations (from A) enter from the LEFT, one row per row of PEs
//     - After K cycles, partial sums exit at the BOTTOM = one row of C
//
//   WHY "WEIGHT STATIONARY"?
//     In this design weights also pass through (not truly stationary),
//     but the dataflow is identical to weight-stationary — activations
//     and weights enter from two edges and meet inside the grid.
//
// PARAMETERS:
//   N         : array dimension (NxN grid of PEs). Start with 8.
//   DATA_WIDTH: input bit-width (8 = INT8)
//   ACC_WIDTH : accumulator width (32 = INT32)
//
// PORTS:
//   wgt_in    : N weights entering from the top row  (one per column)
//   act_in    : N activations entering from the left (one per row)
//   psum_out  : N partial sums exiting at the bottom (one per column)
//               After K cycles, these are complete dot products.
//
// =============================================================================

`timescale 1ns/1ps

module systolic_array #(
    parameter int N          = 8,   // array size (NxN)
    parameter int DATA_WIDTH = 8,
    parameter int ACC_WIDTH  = 32
)(
    input  logic                           clk,
    input  logic                           rst_n,

    // Weights enter from the top (one per column)
    input  logic signed [DATA_WIDTH-1:0]   wgt_in  [N],

    // Activations enter from the left (one per row)
    input  logic signed [DATA_WIDTH-1:0]   act_in  [N],

    // Partial sums exit at the bottom (one per column)
    // After K clock cycles, these hold the complete dot products
    output logic signed [ACC_WIDTH-1:0]    psum_out [N]
);

    // -------------------------------------------------------------------------
    // Internal wires connecting adjacent PEs
    //
    // act_h[row][col]  — horizontal activation wire between (row, col-1) and (row, col)
    //   act_h[row][0]   = act_in[row]    (left boundary, driven by input)
    //   act_h[row][N]   = (discarded)    (right boundary, falls off edge)
    //
    // wgt_v[row][col]  — vertical weight wire between (row-1, col) and (row, col)
    //   wgt_v[0][col]   = wgt_in[col]    (top boundary)
    //   wgt_v[N][col]   = (discarded)
    //
    // psum_v[row][col] — vertical partial sum wire
    //   psum_v[0][col]  = 0              (top boundary, start accumulation at 0)
    //   psum_v[N][col]  = psum_out[col]  (bottom boundary, final result)
    // -------------------------------------------------------------------------

    logic signed [DATA_WIDTH-1:0] act_h  [N][N+1];
    logic signed [DATA_WIDTH-1:0] wgt_v  [N+1][N];
    logic signed [ACC_WIDTH-1:0]  psum_v [N+1][N];

    // ---- Boundary conditions ----
    // Left edge: feed activations in
    // Top edge:  feed weights in, zero out partial sums
    for (genvar r = 0; r < N; r++) begin
        assign act_h[r][0]  = act_in[r];   // activations enter left edge
        assign psum_v[0][r] = '0;          // partial sums start at zero
    end
    for (genvar c = 0; c < N; c++) begin
        assign wgt_v[0][c]  = wgt_in[c];   // weights enter top edge
    end

    // ---- Bottom boundary: connect final psum row to output ----
    for (genvar c = 0; c < N; c++) begin
        assign psum_out[c] = psum_v[N][c];
    end

    // ---- Instantiate the N×N PE grid ----
    for (genvar r = 0; r < N; r++) begin : row
        for (genvar c = 0; c < N; c++) begin : col
            pe #(
                .DATA_WIDTH (DATA_WIDTH),
                .ACC_WIDTH  (ACC_WIDTH)
            ) u_pe (
                .clk      (clk),
                .rst_n    (rst_n),
                // Activation: enters from left, exits right
                .act_in   (act_h[r][c]),
                .act_out  (act_h[r][c+1]),
                // Weight: enters from top, exits bottom
                .wgt_in   (wgt_v[r][c]),
                .wgt_out  (wgt_v[r+1][c]),
                // Partial sum: enters from top (0 at top edge), exits bottom
                .psum_in  (psum_v[r][c]),
                .psum_out (psum_v[r+1][c])
            );
        end
    end

endmodule
