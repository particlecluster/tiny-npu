`timescale 1ns/1ps

module tb_systolic_array;

    localparam int N          = 2;
    localparam int DATA_WIDTH = 8;
    localparam int ACC_WIDTH  = 32;

    logic                          clk = 0;
    logic                          rst_n = 0;
    logic                          load_wgt = 0;
    logic signed [DATA_WIDTH-1:0]  wgt_in   [N];
    logic signed [ACC_WIDTH-1:0]   psum_top [N];
    logic signed [DATA_WIDTH-1:0]  act_in   [N];
    wire signed [ACC_WIDTH-1:0]   psum_out [N];

    systolic_array #(
        .N(N), .DATA_WIDTH(DATA_WIDTH), .ACC_WIDTH(ACC_WIDTH)
    ) dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .load_wgt (load_wgt),
        .wgt_in   (wgt_in),
        .psum_top (psum_top),
        .act_in   (act_in),
        .psum_out (psum_out)
    );

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
            $display("  [FAIL] %s: got %0d (hex: %h), expected %0d", name, got, got, expected);
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

        // Initialize all inputs
        rst_n = 0;
        load_wgt = 0;
        for (int i = 0; i < N; i++) begin
            wgt_in[i]   = 8'sd0;
            psum_top[i] = 32'sd0;
            act_in[i]   = 8'sd0;
        end

        // Reset pulse
        repeat(2) @(posedge clk);
        #1 rst_n = 1;
        @(posedge clk);

        // ----------------------------------------------------
        // 1. Load Weights: B = [[5, 6], [7, 8]]
        // Row 1 enters first, then Row 0 pushes it down
        // ----------------------------------------------------
        $display("\n[PHASE 1] Loading Weights...");
        #1;
        load_wgt = 1;
        wgt_in[0] = 8'sd7; wgt_in[1] = 8'sd8; // Row 1 of B
        @(posedge clk);

        #1;
        wgt_in[0] = 8'sd5; wgt_in[1] = 8'sd6; // Row 0 of B
        @(posedge clk);

        #1;
        load_wgt = 0;
        wgt_in[0] = 8'sd0; wgt_in[1] = 8'sd0;

        // ----------------------------------------------------
        // 2. Stream Activations: A = [[1, 2], [3, 4]]
        // Row 0 of A (1, 2) fed to act_in[0]
        // Row 1 of A (3, 4) fed to act_in[1] (delayed by 1 cycle)
        // ----------------------------------------------------
        $display("\n[PHASE 2] Computing GEMM...");

        // Cycle 0: Feed A[0][0]=1 into Row 0. Row 1 gets 0.
        #1;
        act_in[0] = 8'sd1; act_in[1] = 8'sd0;
        @(posedge clk);

        // Cycle 1: Feed A[1][0]=3 into Row 0. Feed A[0][1]=2 into Row 1.
        #1;
        act_in[0] = 8'sd3; act_in[1] = 8'sd2;
        @(posedge clk);

        // Cycle 2: Feed A[1][1]=4 into Row 1. Row 0 gets 0.
        // At this point, PE(1,0) outputs c00 = 1*5 + 2*7 = 19
        #1;
        check("c00 (Row 0, Col 0)", psum_out[0], 32'sd19);
        act_in[0] = 8'sd0; act_in[1] = 8'sd4;
        @(posedge clk);

        // Cycle 3: All activations finished.
        // At this point:
        //  Col 1 outputs c01 = 1*6 + 2*8 = 22
        //  Col 0 outputs c10 = 3*5 + 4*7 = 43
        #1;
        check("c01 (Row 0, Col 1)", psum_out[1], 32'sd22);
        check("c10 (Row 1, Col 0)", psum_out[0], 32'sd43);
        act_in[0] = 8'sd0; act_in[1] = 8'sd0;
        @(posedge clk);

        // Cycle 4:
        // At this point:
        //  Col 1 outputs c11 = 3*6 + 4*8 = 50
        #1;
        check("c11 (Row 1, Col 1)", psum_out[1], 32'sd50);
        @(posedge clk);

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
