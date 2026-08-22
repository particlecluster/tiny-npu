// =============================================================================
// skew_buffer.sv — Hardware Activation Skew Controller for Systolic Array
//
// PURPOSE:
//   Memory delivers an unskewed N-element activation vector (flat_in[N])
//   in parallel each clock cycle.
//
//   The weight-stationary 2D systolic array requires row i to receive its
//   activations delayed by exactly i clock cycles so that activations align
//   with partial sums propagating down the array.
//
// DATAFLOW:
//   - Row 0: 0-cycle delay (direct wire connection: skew_out[0] = flat_in[0])
//   - Row i (i > 0): i-cycle delay using a depth-i shift register of flip-flops.
//   - skew_out[N] directly drives act_in[N] of systolic_array.sv.
//
// =============================================================================

`timescale 1ns/1ps

module skew_buffer #(
    parameter int N          = 8,   // Dimension of the systolic array (NxN)
    parameter int DATA_WIDTH = 8    // INT8 activations
)(
    input  logic                          clk,
    input  logic                          rst_n,

    // Unskewed parallel activation input vector from memory/buffer
    input  logic signed [DATA_WIDTH-1:0]  flat_in  [N],

    // Skewed activation output vector connected to systolic_array.act_in
    output logic signed [DATA_WIDTH-1:0]  skew_out [N]
);

    // Row 0: 0 cycles delay (direct pass-through)
    assign skew_out[0] = flat_in[0];

    // Rows 1 to N-1: depth-i shift register pipeline
    for (genvar i = 1; i < N; i++) begin : gen_skew_row
        logic signed [DATA_WIDTH-1:0] shift_reg [i];

        always_ff @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                for (int d = 0; d < i; d++) begin
                    shift_reg[d] <= '0;
                end
            end else begin
                shift_reg[0] <= flat_in[i];
                for (int d = 1; d < i; d++) begin
                    shift_reg[d] <= shift_reg[d-1];
                end
            end
        end

        assign skew_out[i] = shift_reg[i-1];
    end

endmodule
