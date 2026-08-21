// =============================================================================
// pe.sv — Processing Element (the single cell of the systolic array)
//
// HOW IT WORKS:
//   This is a 1-cycle pipelined MAC (Multiply-ACcumulate) unit.
//   Think of it like one stage in your CPU pipeline — data flows in,
//   something happens, data flows out, all in one clock cycle.
//
//   In the systolic array grid:
//     - Activations stream LEFT → RIGHT (like data in a shift register)
//     - Weights flow TOP → BOTTOM (passed down each cycle)
//     - Partial sums accumulate TOP → BOTTOM (add our contribution each cycle)
//
//   Each cycle: psum_out = psum_in + (weight * activation)
//
// PARAMETERS:
//   DATA_WIDTH : bit-width of inputs (8 for INT8)
//   ACC_WIDTH  : bit-width of accumulator (32 to avoid overflow)
//
// =============================================================================

`timescale 1ns/1ps

module pe #(
    parameter int DATA_WIDTH = 8,   // INT8 inputs
    parameter int ACC_WIDTH  = 32   // INT32 accumulator (prevents overflow)
)(
    input  logic                          clk,
    input  logic                          rst_n,   // active-low reset

    // ---- Activation path: flows LEFT → RIGHT across the array ----
    input  logic signed [DATA_WIDTH-1:0]  act_in,
    output logic signed [DATA_WIDTH-1:0]  act_out,

    // ---- Weight path: flows TOP → BOTTOM down the array ----
    input  logic signed [DATA_WIDTH-1:0]  wgt_in,
    output logic signed [DATA_WIDTH-1:0]  wgt_out,

    // ---- Partial sum path: accumulates TOP → BOTTOM ----
    // psum_in comes from the PE above; we add our MAC and pass it down
    input  logic signed [ACC_WIDTH-1:0]   psum_in,
    output logic signed [ACC_WIDTH-1:0]   psum_out
);

    // -------------------------------------------------------------------------
    // Registered pipeline stage
    // All outputs update on the rising edge of clk.
    // This is what makes the systolic array "systolic" — everything is
    // registered and moves in lockstep, one step per clock cycle.
    // -------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            act_out  <= '0;
            wgt_out  <= '0;
            psum_out <= '0;
        end else begin
            act_out  <= act_in;                         // pass activation right
            wgt_out  <= wgt_in;                         // pass weight down
            psum_out <= psum_in + (wgt_in * act_in);   // MAC + accumulate
        end
    end

endmodule
