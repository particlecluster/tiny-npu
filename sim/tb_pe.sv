// =============================================================================
// tb_pe.sv — Testbench for the Processing Element
//
// HOW TO READ THIS:
//   A testbench is like a "fake world" around your module.
//   We drive inputs and check that outputs match what Python calculated.
//
//   Run this with: .\scripts\run_sim.ps1 -tb pe
//
//   WHAT WE TEST:
//     1. Reset behaviour (outputs should be 0)
//     2. Single MAC: one weight x one activation + partial sum
//     3. Pipeline: verify output appears exactly 1 cycle after input
//     4. Accumulation: run multiple cycles, check running total
//     5. Signed arithmetic: negative weights and activations
//     6. Overflow boundary: near max INT8 values
//
// =============================================================================

`timescale 1ns/1ps

module tb_pe;

    // ---- Parameters (must match pe.sv) ----
    localparam DATA_WIDTH = 8;
    localparam ACC_WIDTH  = 32;

    // ---- DUT (Device Under Test) signals ----
    logic                          clk;
    logic                          rst_n;
    logic signed [DATA_WIDTH-1:0]  act_in;
    logic signed [DATA_WIDTH-1:0]  act_out;
    logic signed [DATA_WIDTH-1:0]  wgt_in;
    logic signed [DATA_WIDTH-1:0]  wgt_out;
    logic signed [ACC_WIDTH-1:0]   psum_in;
    logic signed [ACC_WIDTH-1:0]   psum_out;

    // ---- Instantiate the PE ----
    pe #(
        .DATA_WIDTH (DATA_WIDTH),
        .ACC_WIDTH  (ACC_WIDTH)
    ) dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .act_in   (act_in),
        .act_out  (act_out),
        .wgt_in   (wgt_in),
        .wgt_out  (wgt_out),
        .psum_in  (psum_in),
        .psum_out (psum_out)
    );

    // ---- Clock: 10ns period (100 MHz) ----
    initial clk = 0;
    always #5 clk = ~clk;

    // ---- Test tracking ----
    int pass_count = 0;
    int fail_count = 0;

    // ---- Helper task: check a value and report ----
    task automatic check(
        input string         test_name,
        input logic signed [ACC_WIDTH-1:0] got,
        input logic signed [ACC_WIDTH-1:0] expected
    );
        if (got === expected) begin
            $display("  [PASS] %s: got %0d", test_name, got);
            pass_count++;
        end else begin
            $display("  [FAIL] %s: got %0d, expected %0d", test_name, got, expected);
            fail_count++;
        end
    endtask

    // ---- Main test sequence ----
    initial begin
        $display("\n========================================");
        $display(" PE Testbench");
        $display("========================================");

        // ---- Reset ----
        $display("\n[TEST 1] Reset behaviour");
        rst_n   = 0;
        act_in  = 8'sd0;
        wgt_in  = 8'sd0;
        psum_in = 32'sd0;
        @(posedge clk); #1;  // wait one cycle after reset
        check("act_out after reset",  {{(ACC_WIDTH-DATA_WIDTH){1'b0}}, act_out},  '0);
        check("wgt_out after reset",  {{(ACC_WIDTH-DATA_WIDTH){1'b0}}, wgt_out},  '0);
        check("psum_out after reset", psum_out, '0);
        rst_n = 1;  // release reset

        // ---- Test 2: Single MAC ----
        // Expected: psum_out = psum_in + (wgt_in * act_in)
        //         =    100  + (   3   *    4   ) = 112
        $display("\n[TEST 2] Single MAC: 100 + (3 * 4) = 112");
        act_in  = 8'sd4;
        wgt_in  = 8'sd3;
        psum_in = 32'sd100;
        @(posedge clk); #1;
        check("psum_out", psum_out, 32'sd112);
        check("act_out passthrough",  {{(ACC_WIDTH-DATA_WIDTH){act_out[DATA_WIDTH-1]}}, act_out},  {{(ACC_WIDTH-DATA_WIDTH){1'sb0}}, 32'sd4});
        check("wgt_out passthrough",  {{(ACC_WIDTH-DATA_WIDTH){wgt_out[DATA_WIDTH-1]}}, wgt_out},  {{(ACC_WIDTH-DATA_WIDTH){1'sb0}}, 32'sd3});

        // ---- Test 3: Signed arithmetic (negative weight) ----
        // Expected: 0 + (-5 * 7) = -35
        $display("\n[TEST 3] Signed: 0 + (-5 * 7) = -35");
        act_in  = 8'sd7;
        wgt_in  = -8'sd5;
        psum_in = 32'sd0;
        @(posedge clk); #1;
        check("psum_out (neg weight)", psum_out, -32'sd35);

        // ---- Test 4: Both negative ----
        // Expected: 0 + (-3 * -4) = +12
        $display("\n[TEST 4] Signed: 0 + (-3 * -4) = 12");
        act_in  = -8'sd4;
        wgt_in  = -8'sd3;
        psum_in = 32'sd0;
        @(posedge clk); #1;
        check("psum_out (neg * neg)", psum_out, 32'sd12);

        // ---- Test 5: Accumulation over multiple cycles ----
        // Cycle 1: 0 + (2 * 3) = 6
        // Cycle 2: 6 + (4 * 5) = 26
        // Cycle 3: 26 + (1 * 1) = 27
        $display("\n[TEST 5] Multi-cycle accumulation");
        act_in  = 8'sd3; wgt_in = 8'sd2; psum_in = 32'sd0;
        @(posedge clk); #1;
        check("acc cycle 1", psum_out, 32'sd6);

        act_in  = 8'sd5; wgt_in = 8'sd4; psum_in = psum_out;
        @(posedge clk); #1;
        check("acc cycle 2", psum_out, 32'sd26);

        act_in  = 8'sd1; wgt_in = 8'sd1; psum_in = psum_out;
        @(posedge clk); #1;
        check("acc cycle 3", psum_out, 32'sd27);

        // ---- Test 6: Max INT8 values (check no overflow in INT32 acc) ----
        // 127 * 127 = 16129 -- fits in INT32, should be fine
        $display("\n[TEST 6] Max INT8: 0 + (127 * 127) = 16129");
        act_in  = 8'sd127;
        wgt_in  = 8'sd127;
        psum_in = 32'sd0;
        @(posedge clk); #1;
        check("psum_out (max INT8)", psum_out, 32'sd16129);

        // ---- Test 7: Zero inputs ----
        $display("\n[TEST 7] Zero: psum_in=999 + (0 * 0) = 999");
        act_in  = 8'sd0;
        wgt_in  = 8'sd0;
        psum_in = 32'sd999;
        @(posedge clk); #1;
        check("psum_out (zero inputs)", psum_out, 32'sd999);

        // ---- Summary ----
        $display("\n========================================");
        $display(" Results: %0d PASSED, %0d FAILED", pass_count, fail_count);
        $display("========================================\n");

        if (fail_count == 0)
            $display("ALL TESTS PASSED - PE is correct!");
        else
            $display("FAILURES DETECTED -- check the waveform in wave_pe.vcd");

        $finish;
    end

    // ---- VCD dump for GTKWave ----
    initial begin
        $dumpfile("sim/vectors/wave_pe.vcd");
        $dumpvars(0, tb_pe);
    end

endmodule
