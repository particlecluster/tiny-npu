// =============================================================================
// tb_pe.sv — Testbench for Weight-Stationary Processing Element
// =============================================================================

`timescale 1ns/1ps

module tb_pe;

    localparam DATA_WIDTH = 8;
    localparam ACC_WIDTH  = 32;

    logic                          clk, rst_n, load_wgt;
    logic signed [DATA_WIDTH-1:0]  act_in, act_out, wgt_in, wgt_out;
    logic signed [ACC_WIDTH-1:0]   psum_in, psum_out;

    pe #(
        .DATA_WIDTH (DATA_WIDTH),
        .ACC_WIDTH  (ACC_WIDTH)
    ) dut (
        .clk, .rst_n, .load_wgt,
        .act_in, .act_out,
        .wgt_in, .wgt_out,
        .psum_in, .psum_out
    );

    initial clk = 0;
    always #5 clk = ~clk;

    int pass_count = 0;
    int fail_count = 0;

    task automatic check(
        input string                      name,
        input logic signed [ACC_WIDTH-1:0] got,
        input logic signed [ACC_WIDTH-1:0] expected
    );
        if (got === expected) begin
            $display("  [PASS] %s: got %0d", name, got);
            pass_count++;
        end else begin
            $display("  [FAIL] %s: got %0d, expected %0d", name, got, expected);
            fail_count++;
        end
    endtask

    initial begin
        $display("\n========================================");
        $display(" Weight-Stationary PE Testbench");
        $display("========================================");

        // Reset
        rst_n = 0; load_wgt = 0;
        act_in = 0; wgt_in = 0; psum_in = 0;
        @(posedge clk); #1;
        check("Reset psum", psum_out, 0);
        rst_n = 1;

        // Test 1: Load Weight = 5
        $display("\n[TEST 1] Load stationary weight = 5");
        load_wgt = 1;
        wgt_in = 8'sd5;
        @(posedge clk); #1;
        load_wgt = 0; // weight is now locked in wgt_reg

        // Test 2: Compute with activation = 4, psum_in = 100
        // Expected: 100 + (4 * 5) = 120
        $display("\n[TEST 2] Compute: 100 + (4 * 5) = 120");
        act_in  = 8'sd4;
        psum_in = 32'sd100;
        @(posedge clk); #1;
        check("MAC with stationary weight", psum_out, 32'sd120);

        // Test 3: Next cycle with new activation = -3, same weight 5
        // Expected: 0 + (-3 * 5) = -15
        $display("\n[TEST 3] Next cycle: 0 + (-3 * 5) = -15");
        act_in  = -8'sd3;
        psum_in = 32'sd0;
        @(posedge clk); #1;
        check("Signed act * stationary weight", psum_out, -32'sd15);

        $display("\n========================================");
        $display(" Results: %0d PASSED, %0d FAILED", pass_count, fail_count);
        $display("========================================\n");

        if (fail_count == 0) $display("PE MODULE VERIFIED CORRECT! ✓\n");
        $finish;
    end

    initial begin
        $dumpfile("sim/vectors/wave_pe.vcd");
        $dumpvars(0, tb_pe);
    end

endmodule
