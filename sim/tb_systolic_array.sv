// =============================================================================
// tb_systolic_array.sv — 2x2 Weight-Stationary Verification Testbench
//
// Exactly validates the 2x2 matrix multiplication:
//   A = [[1, 2], [3, 4]]
//   B = [[5, 6], [7, 8]]
//   C = A x B = [[19, 22], [43, 50]]
// =============================================================================

`timescale 1ns/1ps

module tb_systolic_array;

    localparam int N          = 2;
    localparam int DATA_WIDTH = 8;
    localparam int ACC_WIDTH  = 32;

    logic                          clk, rst_n, load_wgt;
    logic signed [DATA_WIDTH-1:0]  wgt_in   [N];
    logic signed [ACC_WIDTH-1:0]   psum_top [N];
    logic signed [DATA_WIDTH-1:0]  act_in   [N];
    logic signed [ACC_WIDTH-1:0]   psum_out [N];

    systolic_array #(
        .N(N), .DATA_WIDTH(DATA_WIDTH), .ACC_WIDTH(ACC_WIDTH)
    ) dut (
        .clk, .rst_n, .load_wgt,
        .wgt_in, .psum_top, .act_in, .psum_out
    );

    initial clk = 0;
    always #5 clk = ~clk;

    int pass_count = 0, fail_count = 0;

    task automatic check(
        input string                      name,
        input logic signed [ACC_WIDTH-1:0] got,
        input logic signed [ACC_WIDTH-1:0] expected
    );
        if (got === expected) begin
            $display("  [PASS] %s = %0d", name, got);
            pass_count++;
        end else begin
            $display("  [FAIL] %s: got %0d, expected %0d", name, got, expected);
            fail_count++;
        end
    endtask

    initial begin
        $display("\n========================================================");
        $display(" 2x2 Weight-Stationary Systolic Array Verification");
        $display(" A = [[1, 2], [3, 4]]");
        $display(" B = [[5, 6], [7, 8]]");
        $display(" Expected C = [[19, 22], [43, 50]]");
        $display("========================================================");

        // 1. Reset
        rst_n = 0; load_wgt = 0;
        for (int i = 0; i < N; i++) begin
            wgt_in[i] = 0; psum_top[i] = 0; act_in[i] = 0;
        end
        @(posedge clk); #1;
        rst_n = 1;

        // 2. Load Weights B = [[5, 6], [7, 8]]
        // Row 1 (7, 8) loaded first, shifted down, then Row 0 (5, 6)
        $display("\n[PHASE 1] Loading Weights into Array...");
        load_wgt = 1;
        // Cycle L0: feed row 1
        wgt_in[0] = 8'sd7; wgt_in[1] = 8'sd8;
        @(posedge clk); #1;

        // Cycle L1: feed row 0 (row 1 shifts down to PE(1,0) and PE(1,1))
        wgt_in[0] = 8'sd5; wgt_in[1] = 8'sd6;
        @(posedge clk); #1;
        load_wgt = 0; // Weights now locked in place!

        // 3. Compute Phase: Stream skewed activations A = [[1, 2], [3, 4]]
        // Row 0 of A fed to act_in[0]: Cycle 0 -> 1, Cycle 1 -> 2
        // Row 1 of A fed to act_in[1]: Cycle 0 -> 0 (skewed), Cycle 1 -> 3, Cycle 2 -> 4
        $display("\n[PHASE 2] Streaming Activations and Computing...");

        // Cycle 0: act_in[0] = 1, act_in[1] = 0
        act_in[0] = 8'sd1; act_in[1] = 8'sd0;
        @(posedge clk); #1;

        // Cycle 1: act_in[0] = 2, act_in[1] = 3
        act_in[0] = 8'sd2; act_in[1] = 8'sd3;
        @(posedge clk); #1;

        // Cycle 2: act_in[0] = 0, act_in[1] = 4
        // c00 finishes at psum_out[0]! c00 = 1*5 + 2*7 = 19
        act_in[0] = 8'sd0; act_in[1] = 8'sd4;
        check("c00 (Row 0, Col 0)", psum_out[0], 32'sd19);
        @(posedge clk); #1;

        // Cycle 3:
        // c01 finishes at psum_out[1]! c01 = 1*6 + 2*8 = 22
        // c10 finishes at psum_out[0]! c10 = 3*5 + 4*7 = 43
        check("c01 (Row 0, Col 1)", psum_out[1], 32'sd22);
        check("c10 (Row 1, Col 0)", psum_out[0], 32'sd43);
        @(posedge clk); #1;

        // Cycle 4:
        // c11 finishes at psum_out[1]! c11 = 3*6 + 4*8 = 50
        check("c11 (Row 1, Col 1)", psum_out[1], 32'sd50);

        $display("\n========================================================");
        $display(" Results: %0d PASSED, %0d FAILED", pass_count, fail_count);
        $display("========================================================\n");

        if (fail_count == 0) $display("ALL 4 MATRIX OUTPUTS MATCH EXACTLY! ✓\n");
        $finish;
    end

    initial begin
        $dumpfile("sim/vectors/wave_systolic.vcd");
        $dumpvars(0, tb_systolic_array);
    end

endmodule
