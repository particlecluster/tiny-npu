// =============================================================================
// pe.sv — True Weight-Stationary Processing Element (TPU Architecture)
//
// DATAFLOW:
//   1. WEIGHT LOAD PHASE (load_wgt = 1):
//      - Weights stream vertically down the array: wgt_in -> wgt_reg & wgt_out
//      - Each PE latches its assigned weight into stationary wgt_reg.
//
//   2. COMPUTE PHASE (load_wgt = 0):
//      - Weights remain STATIONARY in wgt_reg.
//      - Activations stream horizontally (LEFT -> RIGHT).
//      - Partial sums accumulate vertically (TOP -> BOTTOM).
//
//   MATH (in Compute Phase):
//      psum_out = psum_in + (act_in * wgt_reg)
//
// =============================================================================

`timescale 1ns/1ps

module pe #(
    parameter int DATA_WIDTH = 8,   // INT8
    parameter int ACC_WIDTH  = 32   // INT32
)(
    input  logic                          clk,
    input  logic                          rst_n,
    input  logic                          load_wgt, // 1 = load weight, 0 = compute

    // Activations: stream LEFT -> RIGHT
    input  logic signed [DATA_WIDTH-1:0]  act_in,
    output logic signed [DATA_WIDTH-1:0]  act_out,

    // Weights: stream TOP -> BOTTOM during loading
    input  logic signed [DATA_WIDTH-1:0]  wgt_in,
    output logic signed [DATA_WIDTH-1:0]  wgt_out,

    // Partial sums: accumulate TOP -> BOTTOM during compute
    input  logic signed [ACC_WIDTH-1:0]   psum_in,
    output logic signed [ACC_WIDTH-1:0]   psum_out
);

    // Stationary weight register
    logic signed [DATA_WIDTH-1:0] wgt_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            act_out  <= '0;
            wgt_out  <= '0;
            wgt_reg  <= '0;
            psum_out <= '0;
        end else begin
            // 1. Weight loading path
            wgt_out <= wgt_in;
            if (load_wgt) begin
                wgt_reg <= wgt_in;
            end

            // 2. Activation pipeline path (shifts right)
            act_out <= act_in;

            // 3. MAC Compute path (accumulates down)
            if (load_wgt) begin
                psum_out <= psum_in;
            end else begin
                psum_out <= psum_in + (act_in * wgt_reg);
            end
        end
    end

endmodule
